include("dependencies.jl")

## Configuration parameters
if !@isdefined(LARGE_WORLD)
    LARGE_WORLD = true
end

ANIMATE = true
USE_1x1 = true

VI_WEEKLY = true
USE_BASELINE = false
USE_OLD_BASELINE = false
USE_ORACLE = false

SOLVE_VI = true
EPISODE_LENGTH = 100

## Experiment parameters
SEEDS = [0x221]
FREQUENCIES = [7] # vcat(1:14, 21)
NUM_AGENTS = 1

## Data collection
data = Dict()

# 52 weeks = 364 days
if !@isdefined(MAX_TIME)
    MAX_TIME = 52*7
end
only_render(time) = true

## Choose solver (value iteration or Q-learning)
title_text = ""

# initialize the solver
if SOLVE_VI
    # max_iterations: maximum number of iterations value iteration runs for (default is 100)
    # belres: the value of Bellman residual used in the solver (defualt is 1e-3)
    solver = ValueIterationSolver(max_iterations=200, belres=1e-6, verbose=false)
    title_text = "Value Iteration"
else
    Random.seed!(0x221) # Determinism
    rng = MersenneTwister(2019)

    # initialize the solver
    # max_iterations: maximum number of iterations value iteration runs for (default is 100)
    # belres: the value of Bellman residual used in the solver (defualt is 1e-3)
    solverQ = QLearningSolver(EpsGreedyPolicy(mdp1, 1.0, rng=rng), learning_rate=0.1, n_episodes=200, max_episode_length=200, eval_every=50, n_eval_traj=10, verbose=false)

    # Use SARSA lambda
    solverSL = SARSALambdaSolver(EpsGreedyPolicy(mdp, 0.0, rng=rng), rng=rng, learning_rate=0.1, lambda=0.9, n_episodes=5000, max_episode_length=50, eval_every=50, n_eval_traj=100, verbose=false)

    title_text = "Q-Learning"
    solver = solverQ
    # solver = solverSL
end


## Simulation propagation and solver
function step(mdp, solver; accumulate::Bool=true, learning::Bool=false, last_state=nothing)
    # propogate environment forward one time step
    if accumulate
        Planning.accumulate!(mdp)
    end

    if learning
        policy = solve(mdp, last_state)
    else
        # solve for an optimal policy
        policy = solve(solver, mdp)
    end

    return policy
end

function find_min_path(mdp, last_state)
    # Find shortest path from current location to closest trash site
    paths = Allocation.path_planning((last_state.x, last_state.y), mdp)
    if isempty(paths)
        minp = nothing
    else
        minp = minimum(p->(length(p.second), p.second), paths)
    end
    return minp
end

import POMDPs.solve
function solve(mdp, last_state)
    # policy comes from A*
    # Find shortest path from current location to closest trash site
    minp = find_min_path(mdp, last_state)

    # Create policy from A* path
    if isnothing(minp)
        policy = FunctionPolicy(s->1) # do nothing
    else
        policy = path2policy(minp[2], last_state)
    end

    return policy
end


function path2policy(path, last_state)
    # Create policy from A* path
    astar_policy = Dict() # state=>action
    prev_state = last_state
    for xy in path
        # select action that leads to xy
        (x,y) = xy
        (px,py) = (prev_state.x,prev_state.y)
        k = (px,py)
        # 1: nothing, 2: up, 3: down, 4: left, 5: right
        if y == py+1
            astar_policy[k] = 2 # up
        elseif y == py-1
            astar_policy[k] = 3 # down
        elseif x == px-1
            astar_policy[k] = 4 # left
        elseif x == px+1
            astar_policy[k] = 5 # right
        else
            astar_policy[k] = 1 # nothing (shouldn't reach here)
        end
        prev_state = Planning.PState(x,y)
    end

    # Collect closest trash location
    # Every time step, visit each location (that you haven't already visited—handled by path_planning)
    policy = FunctionPolicy(function fpolicy(s)
        k = (s.x,s.y)
        if haskey(astar_policy, k)
            return astar_policy[k]
        else
            return 1
        end
    end)

    return policy
end



policy = nothing

# for SEED in SEEDS
SEED = SEEDS[1]

for frequency in FREQUENCIES
    Random.seed!(SEED) # Determinism
    rng = MersenneTwister(2019)

    ## Load MDP code
    include("utils.jl")
    include("TrashWorld.jl")
    using .TrashWorld

    include("Allocation.jl")
    using .Allocation

    include("Planning.jl")
    using .Planning

    include("visualization.jl")

    mdp1 = Planning.PlanningMDP()
    MDPs::Vector{Union{MDP, Nothing}} = fill(nothing, NUM_AGENTS)
    MDPs[1] = mdp1 # original MDP

    AGENT_ORIGINS = [(1,1), (TrashWorld.WORLD_X,TrashWorld.WORLD_Y), (1,TrashWorld.WORLD_Y), (TrashWorld.WORLD_X,1)]

    overflowed = 0
    mean_scores = []
    path_lengths = []

    pdf_prefix = LARGE_WORLD ? "large" : "small"

    scores = []

    @time for time in 1:MAX_TIME
        for (agent_idx,mdp) in enumerate(MDPs)
            # Accumulate all at the same time.
            if !isnothing(mdp)
                Planning.accumulate!(mdp)
            end
        end

        scores = []
        path_length = 0
        score = 0

        for (agent_idx,mdp) in enumerate(MDPs)

            (ox,oy) = AGENT_ORIGINS[agent_idx]
            last_state = Planning.PState(ox,oy)

            if !isnothing(mdp)
                global USE_1x1, title_text

                # propogate environment forward one time step
                # solve for an optimal policy
                policy = step(mdp, solver, accumulate=false, learning=USE_BASELINE, last_state=last_state)

                if ANIMATE && only_render(time)
                    if @isdefined(IJulia)
                        IJulia.clear_output(true)
                    end
                    pdf = false
                    pdfname = "grid_town_initial_agent$agent_idx.pdf"
                    if !LARGE_WORLD
                        pdf = (time==1)
                    end
                    if USE_BASELINE
                        display(render(mdp, last_state, last_state=last_state, policy=policy, time=time, pdf=pdf, pdfname=pdfname))
                    else
                        display(render(mdp, last_state, policy=policy, time=time, pdf=pdf, pdfname=pdfname))
                    end
                end

                if USE_ORACLE
                    # Multi-agent oracle
                    if NUM_AGENTS > 1 && agent_idx == 1
                        origin_paths = map(ai->Allocation.path_planning(AGENT_ORIGINS[ai], mdp, ready=false), 1:NUM_AGENTS)
                        agent_locations = map(_->[], 1:NUM_AGENTS)

                        for k in keys(origin_paths[1]) # Loop over first agents collection of locations
                            # Check which agent has the best path
                            best_agent_idx = argmin(map(ai->length(origin_paths[ai][k]), 1:NUM_AGENTS))
                            push!(agent_locations[best_agent_idx], Planning.TrashWorld.Location(k.x,k.y,k.level,k.rate,false))
                        end

                        for ai in 1:NUM_AGENTS
                            if !isempty(agent_locations[2])
                                @show ai, length(agent_locations[ai])
                                MDPs[ai] = Planning.PlanningMDP(TrashWorld.createworld(agent_locations[ai]), agent_locations[ai])
                            end
                        end

                        mdp = MDPs[agent_idx]
                    end
                    title_text = "Oracle"
                    # for each location
                    prev_x = ox # 1
                    prev_y = oy # 1
                    for location in mdp.locations
                        if location.level >= Planning.COLLECTION_THRESHOLD
                            # then collect.
                            score += Planning.trashrewardmodel(location.level)
                            location.level = 0
                            # path = Perfect Euclidean distance
                            path_length += sqrt(sum(([prev_x, prev_y] - [location.x, location.y]) .^ 2))
                            (prev_x,prev_y) = (location.x,location.y) # to get distance from current point to next
                        end
                    end
                    push!(scores, score)
                    push!(path_lengths, path_length)
                elseif USE_OLD_BASELINE
                    title_text = "Baseline"
                    # on a weekly basis
                    # collect trash from every site
                    if time % 7 == 0
                        for location in mdp.locations
                            location.level = 0
                            path_length += (abs(1-location.x) + abs(1-location.y)) # Manhattan distance
                        end
                        push!(path_lengths, path_length)
                        push!(scores, mdp.world.reward_values...)
                    else
                        push!(scores, 0)
                        push!(path_lengths, 0)
                    end
                else
                    schedule_met::Bool = time % frequency == 0

                    if USE_BASELINE
                        num_ready = length(mdp.locations) # TrashWorld.NUM_LOCATIONS
                    else
                        num_ready = sum(map(l->Planning.trashrewardmodel(l.level) >= 0, mdp.locations)) # captures changes to the reward function
                    end

                    if VI_WEEKLY && !schedule_met
                        num_ready = 0
                    end

                    if num_ready > 0
                        num_ready += 2 # Add "go home" location
                    end

                    if NUM_AGENTS > 1 && agent_idx == 1 # Allocate another agent if it's closer.
                        # Allocation stage:
                        # Old question: Is it better to send another agent out, or let the current agent keep collecting?
                        # New question: From other origin (WORLD_X, WORLD_Y), what "ready" locations are closer to that? Cut MDP and solve two.

                        # for all agents
                            # find paths to locations
                            # find which agents is the closest (tie break to AGENT 1)

                        origin_paths = map(ai->Allocation.path_planning(AGENT_ORIGINS[ai], mdp, ready=false), 1:NUM_AGENTS)
                        agent_locations = map(_->[], 1:NUM_AGENTS)

                        for k in keys(origin_paths[1]) # Loop over first agents collection of locations
                            # Check which agent has the best path
                            best_agent_idx = argmin(map(ai->length(origin_paths[ai][k]), 1:NUM_AGENTS))
                            push!(agent_locations[best_agent_idx], Planning.TrashWorld.Location(k.x,k.y,k.level,k.rate,false))
                        end

                        for ai in 1:NUM_AGENTS
                            if !isempty(agent_locations[2])
                                @show ai, length(agent_locations[ai])
                                MDPs[ai] = Planning.PlanningMDP(TrashWorld.createworld(agent_locations[ai]), agent_locations[ai])
                            end
                        end
                    end

                    mdp = MDPs[agent_idx]

                    # Loop over each ready site, stepping sim. forward and solving each time
                    start_of_journey = true
                    headed_home = false
                    for ready in 1:num_ready
                        rec = HistoryRecorder(max_steps=EPISODE_LENGTH)
                        is = last_state
                        h = simulate(rec, mdp, policy, is)
                        for (s, a, r, sp) in eachstep(h, "(s, a, r, sp)")
                            if ANIMATE && only_render(time)
                                if @isdefined(IJulia)
                                    IJulia.clear_output(true)
                                end
                                if LARGE_WORLD
                                    pdf = (time==MAX_TIME && start_of_journey)
                                    if pdf==false
                                        pdf = (time==MAX_TIME && s.x==1 && s.y==1)
                                    end
                                else
                                      pdf = (time==MAX_TIME && start_of_journey)
                                end
                                pdfname = pdf_prefix * "_trash_grid($(s.x),$(s.y),$(sp.x),$(sp.y),$time))_agent$agent_idx.pdf"

                                display(render(mdp, s, policy=policy, time=time, last_state=last_state, pdf=pdf, pdfname=pdfname))
                                if pdf
                                    return
                                end
                            end

                            path_length+=1
                            start_of_journey = false

                            agent_home_conditions = falses(NUM_AGENTS)
                            for ai in 1:NUM_AGENTS
                                (ox,oy) = AGENT_ORIGINS[ai]
                                agent_home_conditions[ai] = (sp.x == ox && sp.y == oy)
                            end
                            home_condition::Bool = any(agent_home_conditions)

                            if sp in mdp.locations || (headed_home && home_condition)
                                score += r
                                for location in mdp.locations
                                    if location == Planning.Coordinate(sp.x, sp.y)
                                        if location.level == Planning.MAX_LEVEL
                                            overflowed += 1 # Count how often we collect when overflowed
                                        end
                                        location.level = 0
                                    end
                                end
                                if num_ready > 1 && ready < num_ready-2
                                    # Start from last site location (i.e. there are more locations ready to be collected)
                                    last_state = s
                                elseif ready < num_ready-1
                                    # Go "home"
                                    headed_home = true
                                    paths = Allocation.path_planning((s.x, s.y), mdp, origin=true, origin_location=AGENT_ORIGINS[agent_idx])
                                    policy = path2policy(collect(values(paths))[1], s) # Path home to origin.
                                    last_state = s
                                else
                                    (ox,oy) = AGENT_ORIGINS[agent_idx]
                                    last_state = Planning.PState(ox,oy)
                                end
                                break
                            elseif a == 1 # i.e. :nothing
                                push!(path_lengths, 0)
                                break
                            end
                            if !USE_1x1
                                last_state = sp
                            end
                        end

                        if num_ready > 1 && ready < num_ready-2
                            # Note: Old allocation point.

                            # Update reward (i.e. remove trash)
                            Planning.setreward!(mdp.world, mdp.locations)

                            # Re-solve policy
                            if USE_BASELINE
                                policy = solve(mdp, last_state)
                            else
                                policy = solve(solver, mdp)
                            end

                            start_of_journey = true
                        end
                    end
                    push!(path_lengths, path_length)
                    push!(scores, score) # Collect reward when at location (zero otherwise, helps to compare against oracle)
                end
                if isempty(scores)
                    push!(mean_scores, 0)
                else
                    push!(mean_scores, mean(scores))
                end
            end
        end
        if !ANIMATE
            if @isdefined(IJulia)
                IJulia.clear_output(true)
            end
            @show SEED, frequency, time
        end
    end

    ## Plotting
    if false
        fig, ax1 = subplots(figsize=[8,2])
        ax2 = ax1.twinx()
        ax1.plot(mean_scores)
        ax1.plot(0, "--")
        @show mean(mean_scores)
        ax2.plot(0)
        ax2.plot(path_lengths, "--")
        @show mean(path_lengths)

        title("$title_text: Mean rewards and path length ($(Planning.WORLD_X)x$(Planning.WORLD_Y)) [Of=$overflowed] [$(frequency)]")
        xlabel("Episode")
        ax1.set_ylabel("Reward")
        ax2.set_ylabel("Path length")
        ax1.legend(["Mean Reward ($(round(mean(mean_scores),digits=2)))",
                    "Mean Path Length ($(round(mean(path_lengths),digits=2)))"],
                   loc="upper center", bbox_to_anchor=[0.5, -0.125], fancybox=true, shadow=true, ncol=2);
        @show ax1.get_ylim()
        @show ax2.get_ylim()
    end

    data[(SEED, frequency)] =
        Dict("scores"=>mean(mean_scores),
             "path_length"=>mean(path_lengths),
             "overflowed"=>overflowed)
end

# @show data