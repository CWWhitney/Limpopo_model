library(DiagrammeR)

grViz("
  digraph causal_model {
    graph [layout = dot, rankdir = LR]

    node [shape = box, style = filled, fontname = Helvetica, fillcolor = white]

    // Nodes with line breaks
    Laws
    CommunityIssues
    SocioPoliticalObstacles [label = 'Socio-political obstacles\n(Rights to land and water)']
    AvailableArea
    DemandFarmArea
    ResourceEndowment [label = 'Resource endowment\n(labor, inputs, capital, knowledge)']
    Motivation
    NeedsSuccessfulAgriculture [label = 'Needs of successful\nsubsistence agriculture']
    FarmExtension
    ManagementIntegrity [label = 'Management integrity\n/ quality']
    FarmedArea
    WaterNeeds
    LivestockType [label = 'Livestock Type,\nbreed']
    CropChoice
    Environment
    MarketNeeds
    Climate
    WaterAvailability
    Sedimentation
    IrrigationNeeds
    Rainfall [label = 'Rainfall\n(seasonal)']
    Evapotranspiration
    Covers [label = 'Covers\n(Shade nets)']
    Efficiency [label = 'Efficiency\n(Pumps, channels)']
    DistanceToWater
    Losses
    SchedulingEfficiency [label = 'Efficiency of scheduling\n/ allocation']
    SeasonalNeeds [label = 'Seasonal irrigation needs\n(crop water gap)']

    // Simulated Legend
    LegendRed [label = 'Red: Negative Influence', shape = plaintext, fontcolor = red]
    LegendBlue [label = 'Blue: Positive Influence', shape = plaintext, fontcolor = blue]
    LegendGrey [label = 'Grey: Mixed Influence', shape = plaintext, fontcolor = grey]

    // Position Legend
    LegendRed -> LegendBlue [style = invis]
    LegendBlue -> LegendGrey [style = invis]

    // Edges with colors
    Laws -> SocioPoliticalObstacles [color = red]
    CommunityIssues -> SocioPoliticalObstacles [color = red]
    SocioPoliticalObstacles -> FarmedArea [color = red]
    AvailableArea -> FarmedArea [color = red]
    DemandFarmArea -> FarmedArea [color = red]
    ResourceEndowment -> FarmedArea [color = blue]
    Motivation -> DemandFarmArea [color = blue]
    NeedsSuccessfulAgriculture -> DemandFarmArea [color = blue]
    FarmExtension -> ResourceEndowment [color = blue]
    ResourceEndowment -> ManagementIntegrity [color = blue]
    FarmExtension -> ManagementIntegrity [color = blue]
    FarmedArea -> WaterNeeds [color = blue]
    ManagementIntegrity -> WaterNeeds [color = grey]
    LivestockType -> WaterNeeds [color = grey]
    CropChoice -> WaterNeeds [color = grey]
    NeedsSuccessfulAgriculture -> CropChoice [color = grey]
    Environment -> CropChoice [color = grey]
    MarketNeeds -> CropChoice [color = grey]
    Climate -> Environment [color = grey]
    WaterAvailability -> Environment [color = grey]
    Sedimentation -> WaterAvailability [color = red]
    WaterNeeds -> IrrigationNeeds [color = grey]
    Rainfall -> IrrigationNeeds [color = red]
    Evapotranspiration -> IrrigationNeeds [color = blue]
    Covers -> Evapotranspiration [color = blue]
    DistanceToWater -> Efficiency [color = red]
    Efficiency -> Losses [color = red]
    SchedulingEfficiency -> Losses [color = red]
    IrrigationNeeds -> SeasonalNeeds [color = blue]
    Losses -> SeasonalNeeds [color = red]
  }
")
