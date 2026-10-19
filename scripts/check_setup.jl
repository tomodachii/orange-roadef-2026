using JuMP, HiGHS, JSON3, Graphs

model = Model(HiGHS.Optimizer)
set_silent(model)
@variable(model, x >= 0, Int)
@constraint(model, 2x <= 5)
@objective(model, Max, x)
optimize!(model)
@assert termination_status(model) == MOI.OPTIMAL
@assert isapprox(value(x), 2.0)
println("Julia ", VERSION, "; project: ", Base.active_project())
println("JuMP + HiGHS OK: integer optimum = ", value(x))

data_dir = joinpath(@__DIR__, "..", "SOICT_mathematical_modelling", "project", "setA")
println("instance,nodes,arcs,demands,time_slots,max_segments")
for k in 1:20
    name = "setA-" * lpad(k, 2, '0')
    net = JSON3.read(read(joinpath(data_dir, name * "-net.json"), String))
    tm = JSON3.read(read(joinpath(data_dir, name * "-tm.json"), String))
    scenario = JSON3.read(read(joinpath(data_dir, name * "-scenario.json"), String))
    println(join((name, length(net.nodes), length(net.links), length(tm.demands),
                  tm.num_time_slots, scenario.max_segments), ','))
end
