using PGFPlots

FREQUENCIES = vcat(1:14, 21)
groups = []

for metric in ["scores", "overflowed", "path_length"]
    group = GroupPlot(1,2, groupStyle="vertical sep = 0.75cm")

    if metric == "overflowed" # no need to show both graphs
        bools = [false]
    else
        bools = [false, true]
    end

    for OMIT_BASELINE in bools
        if OMIT_BASELINE
            legend_style = "{at={(0.99,0.03)}, anchor=south east, nodes={scale=0.5, transform shape}}"
            plot_title = ""
            plot_xlabel = "Frequency (days)"
        else
            legend_style = "{at={(0.99,0.03)}, anchor=south east, nodes={scale=0.5, transform shape}}"
            if metric == "overflowed"
                suffix = "Overflow"
            elseif metric == "path_length"
                suffix = "Path Length"
            elseif metric == "scores"
                suffix = "Reward"
            end
            plot_title = "Frequency Sweep: $suffix"
            plot_xlabel = ""
        end

        if metric == "overflowed"
            plot_xlabel = "Frequency (days)"
            legend_style = "{at={(0.01,0.98)}, anchor=north west, nodes={scale=0.5, transform shape}}"
            plot_ylabel = "Overflow Count"
        elseif metric == "path_length"
            legend_style = "{anchor=north east, nodes={scale=0.5, transform shape}}"
            plot_ylabel = "Mean Path Length (mi.)"
        elseif metric == "scores"
            plot_ylabel = "Mean Reward"
        end

        a1 = PGFPlots.Axis(style="width=10cm, height=5cm, grid=both, minor tick num=1, legend style=$legend_style", title=plot_title, xlabel=plot_xlabel, ylabel=plot_ylabel) # Mean Reward/Overflow Count
        X = [FREQUENCIES...]
        Y = [map(f->vi_data[(SEED,f)][metric], FREQUENCIES)...]
        push!(a1, PGFPlots.Linear(X, Y, legendentry="Value Iteration (C)", markSize=1, mark="*", style="blue, solid, mark options={blue}"))
        Y = [map(f->vi_data_dR[(SEED,f)][metric], FREQUENCIES)...]
        push!(a1, PGFPlots.Linear(X, Y, legendentry="Value Iteration (D)", markSize=1, mark="o", style="blue, dashed, mark options={solid}"))

        Y = [map(f->oracle_data[(SEED,f)][metric], FREQUENCIES)...]
        push!(a1, PGFPlots.Linear(X, Y, legendentry="Oracle (C)", markSize=1, mark="triangle*", style="red, solid, mark options={red}"))
        Y = [map(f->oracle_data_dR[(SEED,f)][metric], FREQUENCIES)...]
        push!(a1, PGFPlots.Linear(X, Y, legendentry="Oracle (D)", markSize=1, mark="triangle", style="red, dashed, mark options={solid}"))

        if !OMIT_BASELINE
            Y = [map(f->baseline_data[(SEED,f)][metric], FREQUENCIES)...]
            push!(a1, PGFPlots.Linear(X, Y, legendentry="Baseline (C)", markSize=0.8, mark="square*", style="brown, solid, mark options={brown}"))
            Y = [map(f->baseline_data_dR[(SEED,f)][metric], FREQUENCIES)...]
            push!(a1, PGFPlots.Linear(X, Y, legendentry="Baseline (D)", markSize=0.8, mark="square", style="brown, dashed, mark options={solid}"))
        end

        a1
        push!(group, a1)
    end

    PGFPlots.save("frequency_sweep_$(metric)_combined.pdf", group)

    push!(groups, group)
end

for g in groups
    display(g)
end