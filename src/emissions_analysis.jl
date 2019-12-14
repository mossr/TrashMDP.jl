using Statistics
using JLD

# 1 agent
vi_data = load("data_freq_sweep_vi.jld")["data"]
oracle_data = load("data_freq_sweep_oracle.jld")["data"]
baseline_data = load("data_freq_sweep_baseline.jld")["data"]

# 2 agents
vi_data_agents2 = load("data_freq_sweep_vi_2agents.jld")["data"]
baseline_data_agents2 = load("data_freq_sweep_baseline_2agents.jld")["data"]
oracle_data_agents2 = load("data_freq_sweep_oracle_2agents.jld")["data"]

# 3 agents
vi_data_agents3 = load("data_freq_sweep_vi_3agents.jld")["data"]
baseline_data_agents3 = load("data_freq_sweep_baseline_3agents.jld")["data"]
oracle_data_agents3 = load("data_freq_sweep_oracle_3agents.jld")["data"]

# 4 agents
vi_data_agents4 = load("data_freq_sweep_vi_4agents.jld")["data"]
baseline_data_agents4 = load("data_freq_sweep_baseline_4agents.jld")["data"]
oracle_data_agents4 = load("data_freq_sweep_oracle_4agents.jld")["data"]

SEED = 0x221
FREQ = 8

const GAS_PRICE = 3.904 # in CA as of 12/09/2019 (diesel) # https://www.eia.gov/dnav/pet/pet_pri_gnd_dcus_sca_w.htm
const MPG = mean([4.4, 4.2, 4, 3.9, 6.2, 5.1]) # https://www.tandfonline.com/doi/full/10.1080/10962247.2014.990587
const CO2_KGPM = mean([2.2, 2.5, 2.5, 2.6, 1.6, 2.0])

baseline_agent_data = [baseline_data, baseline_data_agents2, baseline_data_agents3, baseline_data_agents4]
oracle_agent_data = [oracle_data, oracle_data_agents2, oracle_data_agents3, oracle_data_agents4]
vi_agent_data = [vi_data, vi_data_agents2, vi_data_agents3, vi_data_agents4]

for ai in 1:4 # NUM_AGENTS
	println("—"^32, "Num. Agents of $ai", "—"^32)

	baseline_path = baseline_agent_data[ai][SEED, FREQ]["path_length"] # miles
	oracle_path = oracle_agent_data[ai][SEED, FREQ]["path_length"] # miles
	vi_path = vi_agent_data[ai][SEED, FREQ]["path_length"] # miles

	@show baseline_path, oracle_path, vi_path

	baseline_gas_cost = baseline_path/MPG * GAS_PRICE # dollars
	@show baseline_gas_cost

	baseline_emissions = baseline_path*CO2_KGPM # kgs
	@show baseline_emissions

	println("—"^80)

	oracle_gas_cost = oracle_path/MPG * GAS_PRICE # dollars
	@show oracle_gas_cost

	oracle_emissions = oracle_path*CO2_KGPM # kgs
	@show oracle_emissions

	println("—"^80)

	vi_gas_cost = vi_path/MPG * GAS_PRICE # dollars
	@show vi_gas_cost

	vi_emissions = vi_path*CO2_KGPM # kgs
	@show vi_emissions

	println("—"^80)
	baseline_vi_gas_reduction = (baseline_gas_cost - vi_gas_cost)/baseline_gas_cost * 100
	@show baseline_vi_gas_reduction

	baseline_vi_co2_reduction = (baseline_emissions - vi_emissions)/baseline_emissions * 100
	@show baseline_vi_co2_reduction

	println("—"^80)
	oracle_vi_gas_reduction = (oracle_gas_cost - vi_gas_cost)/oracle_gas_cost * 100
	@show oracle_vi_gas_reduction

	oracle_vi_co2_reduction = (oracle_emissions - vi_emissions)/oracle_emissions * 100
	@show oracle_vi_co2_reduction

	println()
	println()
	println()
end