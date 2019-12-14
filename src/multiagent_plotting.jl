using PGFPlots

FREQUENCIES = vcat(1:14, 21)

# 1 agent
vi_data_agents1 = load("data_freq_sweep_vi.jld")["data"]

# 2 agents
vi_data_agents2 = load("data_freq_sweep_vi_2agents.jld")["data"]

# 3 agents
vi_data_agents3 = load("data_freq_sweep_vi_3agents.jld")["data"]

# 4 agents
vi_data_agents4 = load("data_freq_sweep_vi_4agents.jld")["data"]

groups = []


legend_style = "{anchor=north east, nodes={scale=0.65, transform shape}}"
plot_xlabel = "Frequency (days)"
plot_title = "Multi-Agent Frequency Sweep: Path Length"
plot_ylabel = "Mean Path Length (mi.)"

SEED = 0x0221

a1 = PGFPlots.Axis(style="width=10cm, height=5cm, grid=both, minor tick num=1, legend style=$legend_style", title=plot_title, xlabel=plot_xlabel, ylabel=plot_ylabel) # Mean Reward/Overflow Count
X = [FREQUENCIES...]
Y = [map(f->vi_data_agents1[(SEED,f)]["path_length"], FREQUENCIES)...]
push!(a1, PGFPlots.Linear(X, Y, legendentry="Value Iteration (1 agent)", markSize=1, mark="*", style="blue, solid, mark options={blue}"))

Y = [map(f->vi_data_agents2[(SEED,f)]["path_length"], FREQUENCIES)...]
push!(a1, PGFPlots.Linear(X, Y, legendentry="Value Iteration (2 agents)", markSize=1, mark="pentagon*", style="teal, solid, mark options={teal}"))

Y = [map(f->vi_data_agents3[(SEED,f)]["path_length"], FREQUENCIES)...]
push!(a1, PGFPlots.Linear(X, Y, legendentry="Value Iteration (3 agents)", markSize=1, mark="square*", style="cyan, solid, mark options={cyan}"))

Y = [map(f->vi_data_agents4[(SEED,f)]["path_length"], FREQUENCIES)...]
push!(a1, PGFPlots.Linear(X, Y, legendentry="Value Iteration (4 agents)", markSize=1, mark="triangle*", style="olive, solid, mark options={olive}"))

PGFPlots.save("frequency_sweep_path_length_multiagents.pdf", a1)
a1