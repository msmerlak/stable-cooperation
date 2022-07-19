using Distributions, LinearAlgebra
using UnPack
using ThreadsX
using Measurements

mutable struct Agent 
    sharing_fraction::Float64
    wealth::Float64
    income::Float64
end

mutable struct Population
    agents::Vector{Agent}
    returns_dist
    sharing_type
end

ppart(x) = x > 0 ? x : 1e-8
function grow!(population::Population)

    returns = rand(population.returns_dist)
    for (agent, r) in zip(population.agents, returns)
        agent.income = (r - 1) * agent.wealth
    end
    
end

function share!(population::Population)

    if population.sharing_type == :wealth

        pool = sum([agent.sharing_fraction * agent.wealth for agent in population.agents])

        for agent in population.agents 
            agent.wealth *= (1 - agent.sharing_fraction)
            agent.income += pool/length(population.agents)
        end

    elseif population.sharing_type == :income

        pool = sum([agent.sharing_fraction * agent.income for agent in population.agents])

        for agent in population.agents 
            agent.income *= (1 - agent.sharing_fraction)
            agent.income += pool/length(population.agents)
        end

    end
end

function cashin!(population::Population)
    for agent in population.agents
        agent.wealth += agent.income 
        if agent.wealth < 0 agent.wealth = 1e-6 end
    end
end

function step!(population::Population)
    wealths = [agent.wealth for agent in population.agents]
    grow!(population)
    share!(population)
    cashin!(population)
    return wealths
end

wealth_series(population; T = 100) = reduce(hcat, [step!(population) for _ in 1:T])'

import Base.log
log(x::VecOrMat) = log.(x)
function sim(p; T = 100)

    @unpack n, sharing_fractions, r, σ, ρ = p 

    agents = [Agent(α, 1, 0) for α in sharing_fractions]
    
    Σ = fill(ρ * σ^2, n, n)
    Σ[diagind(Σ)] .= fill(σ^2, n)

    dist = MultivariateNormal(fill(r, n), Σ)
    
    population = Population(agents, dist, p[:type])


    W = wealth_series(population; T = T)
    return (
        all = W, 
        mean = mapslices(mean, W; dims = 2), 
        median = mapslices(median, W; dims = 2),
        logmean = mapslices(mean ∘ log, W; dims = 2)
        )
end

function sims(p; T = 100, repetitions = 100)
    sims = ThreadsX.collect(sim(p; T = T) for _ in 1:repetitions)
    
    f = [log(s.all[end, 1])/T for s in sims]
    m = [s.mean[end] for s in sims]
    med = [s.median[end] for s in sims]
    lm = [s.logmean[end] for s in sims]
    
    return (
        mean = mean(m) ± std(m)/repetitions,
        median = mean(med) ± std(med)/repetitions,
        logmean = mean(lm) ± std(lm)/repetitions,
        first = mean(f) ± std(f)/repetitions
    )
end