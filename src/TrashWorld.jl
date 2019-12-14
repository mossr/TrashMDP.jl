# Resource Allocation and Planning for Automated Trash Collection
# CS221 Final Project, Robert Moss, Fall 2019

# GridWorld formulation of the trash collection problem
# Common functions and values stored here.
module TrashWorld

using Random
using POMDPModels
using POMDPModelTools
using POMDPs
using Distributions
using StatsBase
using Parameters
using Statistics

export Location,
       Coordinate,
       in,
       ==,
       isready,
       NUM_ROADS,
       NUM_LOCATIONS,
       WORLD_X,
       WORLD_Y,
       MAX_LEVEL,
       MAX_RATE,
       COLLECTION_THRESHOLD,
       roads,
       locations,
       setreward!,
       trashrewardmodel,
       world


const MAX_LEVEL = 100 # [0-100]
const MAX_RATE = 10 # [1-10]
const COLLECTION_THRESHOLD = 80
const GAS_PRICE = 3.904 # in CA as of 12/09/2019 (diesel) # https://www.eia.gov/dnav/pet/pet_pri_gnd_dcus_sca_w.htm
const MPG = mean([4.4, 4.2, 4, 3.9, 6.2, 5.1]) # https://www.tandfonline.com/doi/full/10.1080/10962247.2014.990587
const CO2_KGPM = mean([2.2, 2.5, 2.5, 2.6, 1.6, 2.0])

@with_kw mutable struct Location
    x::Int # x-coordinate in the world
    y::Int # y-coordinate in the world
    level::Int = 0 # trash accumulation level [0-100]
    rate::Int  = 1 # fill-rate (trash/time), relative to own fill capacity [0-10] (0 rate indicates no trash could accumulate here)
    offloaded::Bool = false # indication that the location is taken by another agent
end

import Base.isready
isready(location::Location) = location.level >= COLLECTION_THRESHOLD

struct Coordinate
    x::Int
    y::Int
end


# Multiple dispatch for "==" and "in" functions
import Base.==
==(coord::Coordinate, location::Location) = location.x == coord.x && location.y == coord.y
==(location::Location, coord::Coordinate) = coord == location


import Base.in
function in(coord::Coordinate, locations::Vector{Location})
    for location in locations
        if coord == location
            return true
        end
    end
    return false
end


function trashrewardmodel(level::Number, constant::Bool=true)
    multiplier = 1e2 # 1e3
    if level < TrashWorld.COLLECTION_THRESHOLD
        return multiplier*(sqrt(level/MAX_LEVEL) - 0.9)
    else
        if constant
            return multiplier
        else
            if !constant
                multiplier*=2
            end
            return multiplier*(sqrt((MAX_LEVEL-level+1)/MAX_LEVEL))
        end
    end
end


function cleargridworld!(world::LegacyGridWorld)
    world.reward_states = []
    world.reward_values = []
    world.terminals = Set()
    world.tprob = 1
    return world::LegacyGridWorld
end


function createworld(locations::Vector)
    world = cleargridworld!(LegacyGridWorld(WORLD_X, WORLD_Y))
    world = setreward!(world, locations)
    return world::LegacyGridWorld
end


function setreward!(world, locations)
    world.reward_states = []
    world.reward_values = []
    for (i,loc) in enumerate(locations)
        push!(world.reward_states, GridWorldState(loc.x,loc.y,true))
        # push!(world.reward_values, loc.level)
        push!(world.reward_values, trashrewardmodel(loc.level))
    end
    return world
end

initzero = true # initialize fill-level to all zeros

if isdefined(Main, :LARGE_WORLD) && Main.LARGE_WORLD
    const WORLD_X = 19
    const WORLD_Y = 19

    locations = [
        Location(x=3,y=3,level=initzero ? 0 : 0,rate=1),
        Location(x=5,y=2,level=initzero ? 0 : 30,rate=3),
        Location(x=8,y=2,level=initzero ? 0 : 20,rate=2),
        Location(x=12,y=3,level=initzero ? 0 : 8,rate=4),
        Location(x=14,y=3,level=initzero ? 0 : 60,rate=2),
        Location(x=18,y=2,level=initzero ? 0 : 12,rate=3),

        Location(x=2,y=5,level=initzero ? 0 : 44,rate=1),
        Location(x=5,y=6,level=initzero ? 0 : 20,rate=2),
        Location(x=9,y=5,level=initzero ? 0 : 6,rate=5),
        Location(x=11,y=5,level=initzero ? 0 : 80,rate=2),
        Location(x=15,y=6,level=initzero ? 0 : 79,rate=1),
        Location(x=18,y=6,level=initzero ? 0 : 2,rate=2),

        Location(x=3,y=9,level=initzero ? 0 : 10,rate=1),
        Location(x=6,y=8,level=initzero ? 0 : 24,rate=2),
        Location(x=9,y=9,level=initzero ? 0 : 50,rate=5),
        Location(x=12,y=8,level=initzero ? 0 : 4,rate=4),
        Location(x=14,y=8,level=initzero ? 0 : 1,rate=2),
        Location(x=18,y=9,level=initzero ? 0 : 33,rate=3),

        Location(x=3,y=9+3,level=initzero ? 0 : 0,rate=2),
        Location(x=5,y=9+2,level=initzero ? 0 : 30,rate=1),
        Location(x=8,y=9+2,level=initzero ? 0 : 20,rate=3),
        Location(x=12,y=9+3,level=initzero ? 0 : 8,rate=1),
        Location(x=14,y=9+3,level=initzero ? 0 : 60,rate=4),
        Location(x=18,y=9+2,level=initzero ? 0 : 12,rate=1),

        Location(x=2,y=9+5,level=initzero ? 0 : 40,rate=5),
        Location(x=5,y=9+6,level=initzero ? 0 : 10,rate=4),
        Location(x=9,y=9+5,level=initzero ? 0 : 6,rate=2),
        Location(x=11,y=9+5,level=initzero ? 0 : 30,rate=1),
        Location(x=15,y=9+6,level=initzero ? 0 : 19,rate=3),
        Location(x=18,y=9+6,level=initzero ? 0 : 12,rate=1),

        Location(x=3,y=9+9,level=initzero ? 0 : 15,rate=2),
        Location(x=6,y=9+8,level=initzero ? 0 : 28,rate=4),
        Location(x=9,y=9+9,level=initzero ? 0 : 30,rate=3),
        Location(x=12,y=9+8,level=initzero ? 0 : 14,rate=2),
        Location(x=14,y=9+8,level=initzero ? 0 : 31,rate=1),
        Location(x=18,y=9+9,level=initzero ? 0 : 3,rate=3),
    ]
    world = createworld(locations)
    roads = vcat(
        Coordinate.(1,1:20),
        Coordinate.(4,1:20),
        Coordinate.(7,1:20),
        Coordinate.(10,1:20),
        Coordinate.(13,1:20),
        Coordinate.(16,1:20),
        Coordinate.(19,1:20),
        Coordinate.(1:20,1),
        Coordinate.(1:20,4),
        Coordinate.(1:20,7),
        Coordinate.(1:20,10),
        Coordinate.(1:20,13),
        Coordinate.(1:20,16),
        Coordinate.(1:20,19),
    )
else
    const WORLD_X = 10
    const WORLD_Y = 10

    constant_rate = false # Testing

    locations = [
        Location(x=3,y=9,level=initzero ? 0 : 10,rate=constant_rate ? 20 : 1),
        Location(x=5,y=6,level=initzero ? 0 : 20,rate=constant_rate ? 20 : 2),
        Location(x=9,y=9,level=initzero ? 0 : 50,rate=constant_rate ? 20 : 5),
        Location(x=8,y=2,level=initzero ? 0 : 20,rate=constant_rate ? 20 : 2)
    ]
    world = createworld(locations)
    roads = vcat(
        Coordinate(1,1),
        Coordinate.(2,1:10),
        Coordinate(3,5),
        Coordinate.(4,2:8),
        [Coordinate.(i,2:3:8) for i in 5:6]...,
        Coordinate.(7, vcat(2:6, 8:10)),
        Coordinate.(8, 4:2:8),
        Coordinate.(9, vcat(4, 6:8)),
        Coordinate.(10,1:4)
    )
end

const NUM_ROADS = length(roads)
const NUM_LOCATIONS = length(locations)

end # module TrashWorld