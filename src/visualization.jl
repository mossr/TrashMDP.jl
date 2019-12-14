using Compose
using ColorSchemes
using LaTeXStrings
using Cairo

function num2s(int, smap)
    str = string(int)
    for pair in smap
        str = replace(str, pair)
    end
    return str
end

function num2sub(int)
    subscripts = ["0"=>"₀", "1"=>"₁", "2"=>"₂", "3"=>"₃", "4"=>"₄", "5"=>"₅", "6"=>"₆", "7"=>"₇", "8"=>"₈", "9"=>"₉"]
    return num2s(int, subscripts)
end

function num2sup(int)
    superscripts = ["0"=>"⁰", "1"=>"¹", "2"=>"²", "3"=>"³", "4"=>"⁴", "5"=>"⁵", "6"=>"⁶", "7"=>"⁷", "8"=>"⁸", "9"=>"⁹"]
    return num2s(int, superscripts)
end

function action2graphic(a, path::Bool=false)
    actions = [:nothing, :up, :down, :left, :right] # Offset version
    arrows = ["•", "↑", "↓", "←", "→"]
    path_arrows = ["•", "↑", "↓", "←", "→"]

    ## Alternate arrow symbols:
    # arrows = ["•", "⇡", "⇣", "⇠", "⇢"]
    # path_arrows = ["•", "⬆", "⬇", "⬅", "➡"]
    # path_arrows = ["•", "￪", "￬", "￩", "￫"]
    # path_arrows = ["•", "⤉", "⤈", "⇷", "⇸"]
    # path_arrows = ["•", "⇧", "⇩", "⇦", "⇨"]
    # path_arrows = ["•", "⬆", "⬇", "⬅", "➡"]
    # path_arrows = ["•", "⇈", "⇊", "⇇", "⇉"]
    return path ? path_arrows[a] : arrows[a]
end

normalize(X) = (X .- minimum(X)) / (maximum(X) .- minimum(X))

import POMDPModelTools.render
function render(mdp::Planning.PlanningMDP, state::Planning.PState; policy=nothing, time=nothing, last_state=nothing, pdf=false, pdfname="graph.pdf")#;

    nx, ny = mdp.world.size_x, mdp.world.size_y
    large_world = nx > 10
    sz = min(w,h)
    world_ctx = context((w-sz)/2, (h-sz)/2, sz, sz)
    cells = []
    location_names = []
    policy_actions = []
    trace_path = []
    grids = []
    li = 1

    if large_world
        normal_fsize = fontsize(6pt)
        large_fsize = fontsize(10pt)
        location_fsize = fontsize(6pt)
        grid_linewidth = linewidth(0.1mm)
        location_text_linewidth = linewidth(0.025mm)
    else
        normal_fsize = fontsize(10pt)
        large_fsize = fontsize(14pt)
        location_fsize = fontsize(10pt)
        grid_linewidth = linewidth(0.25mm)
        location_text_linewidth = linewidth(0.1mm)
    end


    path_coords::Vector{Planning.Coordinate} = []
    if !isnothing(last_state)
        rec = HistoryRecorder(max_steps=100)
        history = simulate(rec, mdp, policy, last_state)
        for (s, a, r, sp) in eachstep(history, "(s, a, r, sp)")
            if a != 1
                ctx_path = cell_ctx((s.x,s.y), (nx,ny))
                path = compose(ctx_path, Compose.text(0.5,0.45, action2graphic(a, true), hcenter, vcenter), Compose.stroke("yellow"), fill("yellow"), large_fsize)
                push!(trace_path, path)
                push!(path_coords, Planning.Coordinate(s.x,s.y))
            end
        end
    end

    for x in 1:nx, y in 1:ny
        ctx = cell_ctx((x,y), (nx,ny))
        coord = Planning.Coordinate(x,y)
        locidx = findall(loc->loc == coord, mdp.locations)
        if coord in mdp.roads
            idx = Planning.stateindex(mdp, Planning.PState(x,y))
            if isnan(idx) || isnothing(policy) || !hasfield(typeof(policy), :qmat)
                clr = "lightgray"
            else
                maxQ = mapslices(maximum, policy.qmat, dims=2)
                valueQ = normalize(maxQ) # normalized to [0-1]
                if all(isnan, valueQ)
                    clr = "lightgray"
                else
                    clr = get(ColorSchemes.Greys_9, valueQ[idx]^10)
                end
            end
        elseif !isempty(locidx)
            location = mdp.locations[locidx[1]]
            label = "$(location.level)٪"
            location_color = "white"
            if location.level >= 94
                location_color = "black"
            end
            location_name = compose(ctx, Compose.text(0.5,0.5,label, hcenter, vcenter), fill(location_color), location_fsize)
            push!(location_names, location_name)
            li+=1
            c = location.level
            clr = tocolor(c)
        else
            clr = "white"
        end
        if !isnothing(policy) && (coord in mdp.roads) && !(coord in path_coords)
            policy_action = compose(ctx, Compose.text(0.5,0.45,action2graphic(Planning.action(policy, Planning.PState(x,y))), hcenter, vcenter), Compose.stroke("white"), fill("white"), normal_fsize)
            push!(policy_actions, policy_action)
        end

        cell = compose(ctx, Compose.rectangle(), fill(clr))

        if !isnothing(policy) && (coord in mdp.roads)
            grid = compose(context(), grid_linewidth, qcolor(), cell)
            push!(grids, grid)
        else
            grid = compose(context(), grid_linewidth, qcolor(), cell)
            push!(grids, grid)
        end
    end

    time_label = nothing
    if time != nothing
        time_label = compose(context(), Compose.text(1.075,0.975,"t = $time", hcenter, vcenter), fill("black"))
    end

    outline = compose(context(), linewidth(1mm), Compose.rectangle())
    locations = compose(context(), location_text_linewidth, Compose.fill("white"), location_names...)
    if !isempty(policy_actions)
        actions = compose(context(), linewidth(0.1mm), Compose.stroke("black"), vcat(trace_path, policy_actions)...)
    end

    step = Dict(:s=>(state.x,state.y))
    if haskey(step, :s)
        agent_ctx = cell_ctx(step[:s], (nx,ny))
        agent_polygon = polygon([(0.1,0.2), (0.1,0.8), (0.9, 0.8), (0.9,0.2)])
        if !isnothing(policy)
            current_action = Planning.action(policy, state)
            if current_action == 2 || current_action == 3
                # up or down, rotate agent
                agent_polygon = polygon([(0.2,0.1), (0.2,0.9), (0.8, 0.9), (0.8,0.1)])
            end
        end
        agent = compose(agent_ctx, agent_polygon, fill("blue"), Compose.stroke("white"), fillopacity(0.5))
    else
        agent = nothing
    end

    if !isempty(policy_actions)
        compose_obj = compose(world_ctx, agent, actions, locations, grids, outline, time_label)
    else
        compose_obj = compose(world_ctx, agent, locations, grids, outline)
    end

    if !isnothing(pdf) && pdf
        # Compose.draw(PDF(pdfname, 10cm, 10cm, dpi=250), compose_obj)
        Compose.draw(PNG(pdfname, 10cm, 10cm, dpi=250), compose_obj)
    end
    return compose_obj
end


function qcolor()
    color = ColorSchemes.RGB(50/255,50/255,50/255)
    return Compose.Compose.stroke(color)
end

function cell_ctx(xy, size)
    nx, ny = size
    x, y = xy
    return context((x-1)/nx, (ny-y)/ny, 1/nx, 1/ny)
end

tocolor(x) = x
function tocolor(r::Int)
    if Planning.trashrewardmodel(r) >= 0
        # green/yellow
        return get(ColorSchemes.summer, (r-Planning.COLLECTION_THRESHOLD)/(Planning.MAX_LEVEL-Planning.COLLECTION_THRESHOLD))
    else
        # red
        return get(ColorSchemes.Reds_9, 1-r/Planning.MAX_LEVEL)
    end
end

nothing # Suppress REPL