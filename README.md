



# CS221: Resource Allocation and Planning for Automated Trash Collection
_Robert Moss, Stanford University, Autumn 2019 (Final Project)_

This repository is for my final project in CS221: Artificial Intelligence: Principles and Techniques at Stanford University.

If you're interested, you can read my final paper here: [`final.pdf`](https://github.com/mossr/TrashMDP.jl/blob/master/final.pdf)

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
- Either open `TrashMDP.jl.ipynb` and run the cells, or open Julia on a command line, cd to `src` and run the following:

```julia
include("simulation.jl")
```

## Visualizations
### Small grid
![Small Grid](plots/small_grid.png?raw=true "Title")

### Large grid
![Large Grid](plots/large_grid.png?raw=true "Title")
