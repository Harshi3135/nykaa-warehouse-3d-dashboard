# nykaa_warehouse_full.rb
# Builds the WHOLE warehouse in SketchUp from a list of bin names:
# bins (named exactly like InstanceName), zone blocks, zone labels,
# aisle markings, floor, dock, packing area and walls.
#
# Bin names must look like  BB-R01-L1-B01  (ZONE-Rack-Level-Bin).

module NykaaWarehouseFull
  # ---- Sizes (change if you want a bigger or smaller look) ----
  BIN_W      = 60.cm    # bin width  (along X)
  BIN_D      = 100.cm   # bin depth  (along Y)
  BIN_H      = 45.cm    # bin height (per level)
  GAP_X      = 5.cm     # gap between bins in a row
  GAP_Z      = 5.cm     # gap between levels
  AISLE      = 150.cm   # walking aisle between racks
  ZONE_GAP   = 400.cm   # space between zones
  MARGIN     = 300.cm   # space between zones and walls
  DOCK_DEPTH = 600.cm   # depth of the dock / packing strip
  WALL_H     = 400.cm
  WALL_T     = 20.cm
  COLUMNS    = 3        # zones per row
  HIDE_WALLS = true     # true = walls are hidden so they are not exported

  # ---- Zone names shown as labels. Add your own zone codes here. ----
  # Example: "SK" => "SKINCARE". Codes not listed show as "ZONE <code>".
  ZONE_NAMES = {
    "BB" => "BATH & BODY"
  }

  PATTERN = /([A-Za-z0-9]+)-R(\d+)-L(\d+)-B(\d+)/

  def self.mat(model, name, r, g, b)
    m = model.materials[name] || model.materials.add(name)
    m.color = Sketchup::Color.new(r, g, b)
    m
  end

  # Solid box from (x0,y0,z0) to (x1,y1,z1), as a named group.
  def self.box(ents, x0, y0, z0, x1, y1, z1, name, material = nil)
    g = ents.add_group
    g.name = name
    pts = [[x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0]]
    f = g.entities.add_face(pts)
    f.reverse! if f.normal.z < 0
    f.pushpull(z1 - z0)
    g.material = material if material
    g
  end

  # Flat 3D text centred at (cx, cy) at height z.
  def self.label(ents, text, cx, cy, z, height, name, material = nil)
    g = ents.add_group
    g.name = name
    g.entities.add_3d_text(text, TextAlignCenter, "Arial", true, false,
                           height, 0.0, 0.0, true, 1.cm)
    g.transform!(Geom::Transformation.new(Geom::Point3d.new(cx, cy, z)))
    g.material = material if material
    g
  end

  def self.run
    path = UI.openpanel("Select the bin list (.txt or .csv)", "", "Text or CSV|*.txt;*.csv||")
    return unless path

    text = File.read(path, encoding: "bom|utf-8")
    bins = {}
    text.scan(PATTERN) do
      m = Regexp.last_match
      bins[m[0]] = [m[1], m[2].to_i, m[3].to_i, m[4].to_i]
    end

    if bins.empty?
      UI.messagebox("No bin names like BB-R01-L1-B01 were found in that file.")
      return
    end

    zones = {}
    bins.each { |name, (z, r, l, b)| (zones[z] ||= []) << [name, r, l, b] }
    codes = zones.keys.sort
    min_level = bins.values.map { |v| v[2] }.min

    # Size of each zone, then one common cell size for the grid.
    dims = {}
    codes.each do |c|
      racks  = zones[c].map { |n| n[1] }.uniq.sort
      min_b  = zones[c].map { |n| n[3] }.min
      max_b  = zones[c].map { |n| n[3] }.max
      width  = (max_b - min_b + 1) * (BIN_W + GAP_X) - GAP_X
      depth  = racks.size * (BIN_D + AISLE) - AISLE
      dims[c] = { racks: racks, min_b: min_b, width: width, depth: depth }
    end
    cell_w = dims.values.map { |d| d[:width] }.max
    cell_d = dims.values.map { |d| d[:depth] }.max
    cols = [COLUMNS, codes.size].min
    rows = (codes.size / COLUMNS.to_f).ceil

    total_w = 2 * MARGIN + cols * cell_w + (cols - 1) * ZONE_GAP
    total_d = DOCK_DEPTH + MARGIN + rows * cell_d + (rows - 1) * ZONE_GAP + MARGIN

    model = Sketchup.active_model
    model.start_operation("Nykaa full warehouse", true)

    # Remove old groups so nothing is duplicated.
    model.entities.grep(Sketchup::Group).each { |g| g.erase! }
    ents = model.entities

    m_floor = mat(model, "NK_Floor", 215, 220, 226)
    m_wall  = mat(model, "NK_Wall", 190, 195, 205)
    m_dock  = mat(model, "NK_Dock", 70, 110, 170)
    m_pack  = mat(model, "NK_Packing", 235, 170, 90)
    m_aisle = mat(model, "NK_Aisle", 240, 210, 60)
    m_text  = mat(model, "NK_Text", 30, 30, 30)

    # Floor
    box(ents, 0, 0, -5.cm, total_w, total_d, 0, "FLOOR", m_floor)

    # Walls
    walls = [
      box(ents, -WALL_T, -WALL_T, 0, total_w + WALL_T, 0, WALL_H, "WALL-S", m_wall),
      box(ents, -WALL_T, total_d, 0, total_w + WALL_T, total_d + WALL_T, WALL_H, "WALL-N", m_wall),
      box(ents, -WALL_T, 0, 0, 0, total_d, WALL_H, "WALL-W", m_wall),
      box(ents, total_w, 0, 0, total_w + WALL_T, total_d, WALL_H, "WALL-E", m_wall)
    ]
    walls.each { |w| w.visible = false } if HIDE_WALLS

    # Dock (left) and packing area (right) along the south edge
    dock_x0 = MARGIN
    dock_x1 = total_w / 2.0 - 100.cm
    pack_x0 = total_w / 2.0 + 100.cm
    pack_x1 = total_w - MARGIN
    box(ents, dock_x0, 100.cm, 0, dock_x1, DOCK_DEPTH - 100.cm, 20.cm, "DOCK", m_dock)
    box(ents, pack_x0, 100.cm, 0, pack_x1, DOCK_DEPTH - 100.cm, 10.cm, "PACKING", m_pack)
    label(ents, "DOCK", (dock_x0 + dock_x1) / 2.0, DOCK_DEPTH / 2.0 - 25.cm, 21.cm, 50.cm, "LABEL-DOCK", m_text)
    label(ents, "PACKING AREA", (pack_x0 + pack_x1) / 2.0, DOCK_DEPTH / 2.0 - 25.cm, 11.cm, 50.cm, "LABEL-PACKING", m_text)

    # Zones
    count = 0
    codes.each_with_index do |c, i|
      col = i % COLUMNS
      row = i / COLUMNS
      zx = MARGIN + col * (cell_w + ZONE_GAP)
      zy = DOCK_DEPTH + MARGIN + row * (cell_d + ZONE_GAP)
      d  = dims[c]

      zones[c].each do |name, r, l, b|
        ri = d[:racks].index(r)
        x0 = zx + (b - d[:min_b]) * (BIN_W + GAP_X)
        y0 = zy + ri * (BIN_D + AISLE)
        z0 = (l - min_level) * (BIN_H + GAP_Z)
        box(ents, x0, y0, z0, x0 + BIN_W, y0 + BIN_D, z0 + BIN_H, name)
        count += 1
      end

      # Aisle markings between racks
      (d[:racks].size - 1).times do |k|
        ay = zy + k * (BIN_D + AISLE) + BIN_D + AISLE / 2.0
        box(ents, zx, ay - 4.cm, 0, zx + d[:width], ay + 4.cm, 0.5.cm, "AISLE-#{c}-#{k + 1}", m_aisle)
      end

      # Zone label in front of the zone
      title = ZONE_NAMES[c] || "ZONE #{c}"
      label(ents, title, zx + d[:width] / 2.0, zy - 130.cm, 0.5.cm, 60.cm, "LABEL-ZONE-#{c}", m_text)
    end

    model.commit_operation
    model.active_view.zoom_extents

    UI.messagebox("Created #{count} bins in #{codes.size} zones, plus floor, walls, " \
                  "dock, packing area, aisle markings and zone labels.")
  end
end

NykaaWarehouseFull.run
