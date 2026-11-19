# nykaa-warehouse-3d-dashboard

An interactive Power BI dashboard that shows a whole warehouse in 3D. Every storage bin is colored by its status and responds to slicers, so you can see which bins are healthy, empty, expiring or expired at a glance.

> **Sample data only.** All data in this project is made up for learning and portfolio purposes. It is not real Nykaa data, and the project is not affiliated with Nykaa.

![Dashboard](images/dashboard.png)

## What it shows

- A 3D warehouse with 576 bins across 6 zones, with a floor, dock and packing area
- Bins colored by status (OK, Expiring, Expired, Empty)
- KPI cards: Total Bins (576), Occupied Bins (487), Occupancy % (84.55%), Space Utilization % (47.91%), Expiring 90d Bins (35)
- Slicers for Zone, Level, Category, Brand and Bin Status
- A donut chart of bin status, a bar chart of quantity by category, and a detail table
- Clicking a slicer highlights the matching bins in 3D and fades the rest

## Warehouse layout

| Zone code | Zone         | Type       |
|-----------|--------------|------------|
| SK        | Skincare     | Ambient    |
| MU        | Makeup       | Ambient    |
| HC        | Haircare     | Ambient    |
| BB        | Bath & Body  | Ambient    |
| RT        | Returns & QC | Quarantine |
| FR        | Fragrance    | Fragile    |

Bins are named `ZONE-Rack-Level-Bin`, for example `BB-R01-L1-B01`. Levels 1-2 are the Golden zone and levels 3-4 are Reserve.

## Bin status colors

| Status   | Color  |
|----------|--------|
| OK       | Green  |
| Expiring | Yellow |
| Expired  | Red    |
| Empty    | Grey   |

## Repository contents

| File                                | Purpose                                                                |
|-------------------------------------|------------------------------------------------------------------------|
| `Nykaa_Warehouse_Report_3D.pbix`    | Power BI report                                                        |
| `Nykaa_Warehouse_Dataset.xlsx`      | Sample data: Dim_Location, Dim_Product, Fact_Inventory, Fact_Movements |
| `Nykaa_Warehouse.skp`               | 3D warehouse model (SketchUp)                                          |
| `Nykaa_Warehouse_3DBI_v2.3dbi`      | Model packaged for the 3DBI Power BI visual                            |
| `nykaa_warehouse_full.rb`           | SketchUp Ruby script that builds the whole warehouse                   |
| `bins.txt`                          | Bin list used as input for the Ruby script                             |
| `images/dashboard.png`              | Dashboard screenshot                                                   |

## How it was built

1. **Data**: the Excel file holds the location, product, inventory and movement tables.
2. **3D model**: in SketchUp, run `nykaa_warehouse_full.rb` (Extensions > Developer > Ruby Console, or load the script) and select `bins.txt`. It creates every bin as a named group, plus zone labels, aisle markings, floor, dock and packing area.
3. **Link**: the 3DBI visual in Power BI matches each bin's `InstanceName` in the data to the group of the same name in the model, so status colors and slicers drive the 3D view.

## How to use

1. Download or clone this repository.
2. Open `Nykaa_Warehouse_Report_3D.pbix` in Power BI Desktop.
3. Use the slicers (Zone, Level, Category, Brand, Bin Status) to filter.
4. Watch the 3D view highlight matching bins and fade the others.

## Tools used

- Power BI Desktop
- 3DBI custom visual
- SketchUp and Ruby
- Excel

## Notes

- The 3DBI visual shows a trial watermark ("not for commercial use"), which is fine for a portfolio project.
- This is a personal learning project with fictional data and has no affiliation with Nykaa.
