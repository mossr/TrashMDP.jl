# Resource Allocation and Planning for Automated Trash Collection
# CS221 Final Project, Robert Moss, Fall 2019

# Allocation MDP formulation
module Allocation

using Random
using POMDPModels
using POMDPModelTools
using POMDPs
using Distributions
using StatsBase
using Parameters
using Statistics
using LightGraphs

# Simply finds the location(s) with the shortest path and then adds that to the .locations of the PlanningMDP.world

include("TrashWorld.jl")
using .TrashWorld
include("Planning.jl")
using .Planning
include("utils.jl")

export path_planning

# Find set of locations that are "ready".
# For each agent, determine where to allocate them based on A*.
    # src = current agent position
    # dst = location(s)

function path_planning(src, mdp; ready::Bool=false, origin::Bool=false, origin_location=(1,1)) # (src, dst)
    # A* shortest path from src to dst with Manhattan distance heuristic
    paths = Dict() # location => path
    source = LI(src...)
    for location in mdp.locations
        if origin || (location.level != 0 && (!ready || isready(location)))
            g = LightGraphs.grid([WORLD_X, WORLD_Y]) # (9,14)

            # Restrict edges to just roads/locations
            for i in 1:WORLD_X*WORLD_Y
                edges_to_remove = []
                for (ei,e) in enumerate(g.fadjlist[i])
                    (x,y) = CI(e)
                    (ix,iy) = CI(i)

                    # Restrict passing through locations other than the target location
                    edge_at_other_location::Bool = false
                    for loc in mdp.locations
                        if loc.x == x && loc.y == y && !(loc.x == location.x && loc.y == location.y)
                            edge_at_other_location = true
                            break
                        end
                    end

                    if !inbounds(mdp.world, x, y, onlyroads=false) || edge_at_other_location
                        # Delete edge (mark for deletion)
                        push!(edges_to_remove, ei)
                    end
                end
                deleteat!(g.fadjlist[i], edges_to_remove)
            end

            if origin
                dst = LI(origin_location...)
            else
                dst = LI(location.x,location.y)
            end

            # Manhattan distance heuristic
            heuristic(src::Int, n::Int) = round(Int,manhattan(CI(src), CI(n)))

            # A* path finding algorithm
            path = a_star(g, source, dst, LightGraphs.weights(g), n->heuristic(source, n))

            paths[location] = []
            for edge in path
                push!(paths[location], CI(edge.dst))
            end

            if origin
                break
            end
        end
    end

    return paths::Dict # location=>path
end

end # module Allocation