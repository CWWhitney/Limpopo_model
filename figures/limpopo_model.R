# Load necessary libraries
library(DiagrammeR)
library(DiagrammeRsvg)
library(rsvg)

# Create the updated graph
overview_graph <- grViz("
  digraph limpopo_model {
    graph [layout = dot, rankdir = LR]

    // Define node styles
    node [shape = box, fontname = Helvetica]

    // Define nodes
    Rainfall [label = 'Rainfall']
    EffectiveRainfall [label = 'Effective Rainfall']
    Evapotranspiration [label = 'Evapotranspiration']
    CropCoefficient [label = 'Crop Coefficient (kc)']
    CropWaterNeed [label = 'Crop Water Need']
    FarmedArea [label = 'Farmed Area']
    TotalCropWaterNeed [label = 'Total Crop Water Need']
    RiverFlow [label = 'River Flow']
    EFlow [label = 'Environmental Flow (e-flow)']
    IrrigationNeed [label = 'Irrigation Need']
    Efficiency [label = 'Efficiency']
    WaterLosses [label = 'Water Losses']
    UsableRiverFlow [label = 'Usable River Flow']
    DamRelease [label = 'Dam Release']
    Scenarios [label = 'Scenarios']
    CropWaterGap [label = 'Crop Water Gap']

    // Define relationships between nodes
    Rainfall -> EffectiveRainfall
    EffectiveRainfall -> CropWaterNeed
    Evapotranspiration -> CropWaterNeed
    CropCoefficient -> CropWaterNeed
    CropWaterNeed -> TotalCropWaterNeed
    FarmedArea -> TotalCropWaterNeed
    TotalCropWaterNeed -> IrrigationNeed
    RiverFlow -> UsableRiverFlow
    EFlow -> UsableRiverFlow
    DamRelease -> UsableRiverFlow
    UsableRiverFlow -> CropWaterGap
    Efficiency -> WaterLosses
    WaterLosses -> IrrigationNeed
    IrrigationNeed -> CropWaterGap
    Scenarios -> CropWaterGap
  }
")

# Save the graph as an SVG file
svg_code <- export_svg(overview_graph)
writeLines(svg_code, "figures/limpopo_model.svg")

# Convert the SVG to a high-quality PNG
rsvg::rsvg_png("figures/limpopo_model.svg", "figures/limpopo_model.png", 
               width = 3000, height = 1200)
