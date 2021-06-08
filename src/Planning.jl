# Resource Allocation and Planning for Automated Trash Collection
# CS221 Final Project, Robert Moss, Fall 2019

# Planning MDP formulation
module Planning

using Random
using POMDPModels
using POMDPModelTools
using POMDPs
using Distributions
using StatsBase
using Parameters
using Statistics

include("TrashWorld.jl")
using .TrashWorld

export PlanningMDP,
    gen,
    reward,
    PState,
    nominal_stateindex,
    inbounds,
    PState


mutable struct PState
    x::Int  # x-coordinate in current grid
    y::Int  # y-coordinate in current grid
    done::Bool

    PState(x,y) = new(x,y,false)
    PState(x,y,done) = new(x,y,done)
end

# Multiple dispatch for "==" and "in" functions
import Base.==
==(coord::PState, location::Location) = location.x == coord.x && location.y == coord.y
==(location::Location, coord::PState) = coord == location

import Base.in
function in(coord::PState, locations::Vector{Location})
    for location in locations
        if coord == location
            return true
        end
    end
    return false
end

struct PlanningMDP <: MDP{PState, Int}
    world::LegacyGridWorld # Underlying GridWorld
    locations::Vector{Location} # Fixed locations in the world that can accumulate trash
    roads::Vector{Coordinate} # Roads to restrict travel
end

POMDPs.isterminal(mdp::PlanningMDP, s::PState) = s.done

# Override "inbounds", i.e. on roads, locations, and not out of the world edges.
import POMDPModels.inbounds
inbounds(mdp::LegacyGridWorld,x::Int64,y::Int64; onlyroads::Bool=false) = (Coordinate(x,y) in roads || (!onlyroads && Coordinate(x,y) in locations)) && (1 <= x <= WORLD_X && 1 <= y <= WORLD_Y)

PlanningMDP() = PlanningMDP(world, locations, roads)
PlanningMDP(locations) = PlanningMDP(world, locations, roads)
PlanningMDP(world, locations) = PlanningMDP(world, locations, roads)

POMDPs.discount(s::PlanningMDP) = 0.99

# Actions - 2-5 for movement, 1 for do nothing (1-4 are GridWorld movements, 1 is nothing for max() tie-breaker)
const N_ACTIONS = 5
POMDPs.actions(s::PlanningMDP) = 1:N_ACTIONS
POMDPs.actionindex(mdp::Planning.PlanningMDP, a::Int) = a

function accumulate!(mdp)
    for location in mdp.locations
        location.level += location.rate
        if location.level > MAX_LEVEL
            location.level = MAX_LEVEL
        end
    end
    setreward!(mdp.world, mdp.locations)
end


# gen: what happens during a single iteration.
function POMDPs.gen(mdp::PlanningMDP, s::PState, a::Int, rng::AbstractRNG)
    if a != 1
        # Move if given movement action
        new_state = POMDPs.gen(DDNOut(:sp), mdp.world, GridWorldState(s.x, s.y, s.done), actions(mdp.world)[a-1], rng) # Offset to adjust for :nothing action (in index 1)
    else
        # Do nothing
        new_state = s
    end

    sp = PState(new_state.x, new_state.y, new_state.done)
    r = reward(mdp,s,a,sp)
    return (sp=sp, r=r)
end

# Reward function
function POMDPs.reward(mdp::PlanningMDP, s::PState, a::Int, sp::PState)
    return static_reward(mdp.world, GridWorldState(sp.x,sp.y,sp.done))
end


# Generate an initial state
function POMDPs.initialstate(mdp::PlanningMDP, rng::AbstractRNG)
    return PState(1, 1) # Start at origin
end


# Convert state to the index (out of WORLD_X*WORLD_Y)
STATE_INDEX = Dict()
function POMDPs.stateindex(mdp::Planning.PlanningMDP, s::Planning.PState)
    if haskey(STATE_INDEX, (s.x,s.y))
        return STATE_INDEX[(s.x,s.y)]
    else
        return 1
    end
end

# Generate the entire vector of states
function POMDPs.states(mdp::Planning.PlanningMDP)
    global STATE_INDEX = Dict()

    state_vect = Vector{Planning.PState}(undef,0)
    local_locations = deepcopy(mdp.locations)

    for cel_idx = 1:(WORLD_X*WORLD_Y)
        # Extract the cartesian indices of the cell
        cart_ind = Tuple(CartesianIndices((mdp.world.size_x, mdp.world.size_y))[cel_idx])
        (x,y) = cart_ind

        # Only add the states that are on the roads or the locations with trash
        location_state = !isempty(findall(loc->loc == Coordinate(x,y), mdp.locations))
        if Coordinate(x,y) in mdp.roads || location_state
            push!(state_vect,Planning.PState(x,y,location_state))
            STATE_INDEX[(x,y)] = length(state_vect)
        end
    end

    return state_vect
end


function POMDPs.transition(mdp::Planning.PlanningMDP, s::Planning.PState, a::Int)
    if a != 1
        grid_world_spcat = transition(mdp.world, GridWorldState(s.x,s.y,s.done), actions(mdp.world)[a-1]) # Offset to adjust for :nothing action (in index 1)

        next_states = Vector{Planning.PState}(undef,0)
        next_probs = Vector{Float64}(undef,0)

        # Now extract the new states and convert to TStates
        for (sp,p) in weighted_iterator(grid_world_spcat)
            push!(next_states, Planning.PState(sp.x, sp.y, sp.done))
            if isnan(p)
                p = 0.0
            end
            push!(next_probs, p)
        end

        return SparseCat(next_states, next_probs)
    else
        # Do nothing
        return SparseCat([s], [1.0])
    end
end

end # module Planning