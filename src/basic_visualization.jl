include("dependencies.jl")

LARGE_WORLD = false
include("Planning.jl")
using .Planning
problem = Planning.PlanningMDP();
include("visualization.jl")

num_episodes = 1 # 100
episode_length = 6 # 5 # 6 #200 # 1000

Random.seed!(0x221) # Determinism
rng = MersenneTwister(2019)
policy_rng = MersenneTwister(1993)

policy = RandomPolicy(problem, rng=policy_rng)

data = DataFrame(s=Int[],a=Int[],r=Int[],sp=Int[])

for i in 1:num_episodes
    rec = HistoryRecorder(max_steps=episode_length)
    is = Planning.PState(1,1)
    h = simulate(rec, problem, policy, is)
    for (s, a, r, sp) in eachstep(h, "(s, a, r, sp)")
        IJulia.clear_output(true)
        for location in problem.locations
            if location == Planning.Coordinate(s.x, s.y)
                location.level = 0
            end
        end
        Planning.accumulate!(problem)
        display(render(problem, is))
        sleep(0.02)
    end
    print("\rDone with episode $i")
end