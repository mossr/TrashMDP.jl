



# Automated Trash Collection using Markov Decision Processes
_Robert Moss, Stanford University, Autumn 2019 (Final Project)_

This repository is for my final project in CS221: Artificial Intelligence: Principles and Techniques at Stanford University.

If you're interested, you can read the research report here: [`trashmdp.pdf`](https://github.com/mossr/TrashMDP.jl/blob/master/trashmdp.pdf)

> **Requirements:** Julia v1.2

## Installation
**Install Julia v1.2** from https://julialang.org/downloads/ (follow their installation steps)

## Files
- **TrashMDP.jl.ipynb**: Jupyter notebook with simulation visualizations
- **src**: Julia source code directory
  - **TrashWorld.jl**: High-level formulation of the grid world
  - **Allocation.jl**: Allocation algorithm for determining shortest path (A*)
  - **Planning.jl**: Markov decision process (MDP) formulation of the trash collection problem
  - **simulation.jl**: Primary code entry point to run simulations and collect data for analysis
  - **dependencies.jl**: Julia package dependencies (running this will tell you what to install via `Pkg.add("...")`)
  - **visualization.jl**: Visualization and animation code
  - **plotting.jl**: Plotting for the metrics collected during simulation
  - **multiagent_plotting.jl**: Plotting for multi-agent analysis
  - **emissions_analysis.jl**: Analysis code for emissions results
  - **basic_visualization.jl**: Basic visualization of the world
  - **utils.jl**: Utility functions (linear indexing and Manhattan distance)
- **plots**: Saved visualizations

## Running
- Either open `TrashMDP.jl.ipynb` and run the cells, or cd to `src` and open a [Jupyter notebook](https://github.com/JuliaLang/IJulia.jl), then run the following:

```julia
include("simulation.jl")
```

## Visualizations
### Small grid
![Small Grid](plots/small_grid.png?raw=true "Title")

### Large grid
![Large Grid](plots/large_grid.png?raw=true "Title")
