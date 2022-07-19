using DrWatson
@quickactivate

using Revise
includet(srcdir("wealth-sharing.jl"))


using Plots; gr(dpi = 500)

### trajectories
a = .2
p = Dict(
    :type => :income,
    :n => 2,
    :r => 1.0,
    :σ => .02,
    :ρ => 0.,
    :sharing_fractions => [0, a]
)

plot([sim(p; T = 500).all[:, 1] for _ in 1:10])

### n identical agents
rhos = 0:.1:.9
alphas = 0:.1:1.
n = 10
S = [sims(
    Dict(
    :type => :income,
    :n => n,
    :r => 1.01,
    :σ => 0.1,
    :ρ => ρ,
    :sharing_fractions => fill(α, n);
    ); 
    T = 100, repetitions = 500).logmean
    for α in alphas,  ρ in rhos]

heatmap(
    alphas,
    rhos,
    [s.val for s in S]',
    xlabel = "α",
    ylabel = "ρ"
)


## 2 agents
n = 2
alphas = 0:.1:1
a = 0.1

plts = []
for T in (10, 1000), type in (:income, :wealth)
    S = [sims(
        Dict(
        :type => type,
        :n => n,
        :r => 1.0,
        :σ => .2,
        :ρ => 0.,
        :sharing_fractions => [α, a]
        ); T = T, repetitions = 1000
        ).first for α in alphas
    ]
    plot(
        alphas,
        S,
        xlabel = "my α",
        ylabel = "(log x(T))/T",
        label = false,
        title = "T = $T, type = $type"
    )
    vline!([a], label = "your α")
    push!(plts, current())
end

plot(plts..., 
size = (800, 600)
)