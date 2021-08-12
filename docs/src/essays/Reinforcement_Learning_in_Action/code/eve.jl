include("utils.jl")
using Lazy
using Plots
using StatsBase
using Match
using LaTeXStrings

gr()
theme(:dark)

# ### Day 1 ###
s0 = [1 0]
plot(layout=@layout([a b c; e f g]))
p_samples = [(0.5, 0.5), (0.2, 0.1), (0.95, 0.7)]
for i in 1:length(p_samples)
    p, q = p_samples[i]
    P = [1-p p; q 1-q]
    states = reductions((x,y) -> x*P, s0, @lazy range(1, 20))
    plot!([x[1] for x in states], ylim=(0,1),subplot=i, label="p=$p\nq=$q")
    plot!([x[2] for x in states], ylim=(0,1), subplot=i+3, label="p=$p\nq=$q")
end

INIT_STATE = 4
REWARD = [3, 0, 0, 0, 0, 0, 0, 0, 5]
ACTIONS = [-1, 1]
STATES = 1:length(REWARD)

function env(init_state, policy, reward_calculator, state_transformer)
    s = init_state
    function play() 
        sₜ  = s
        aₜ = policy(sₜ)
        rₜ = reward_calculator(sₜ, aₜ)
        s = state_transformer(sₜ, aₜ)
        (sₜ, aₜ, rₜ)  # TODO: should return a NamedTuple instead in Julia-0.7
    end
end

# get intermediate State-Action-Reward sequence
get_SAR_seq(play) = @>> begin
    play
    repeatedly 
    takeuntil(res -> ((s, a, r) = res; r > 0))  # TODO: use NamedTuple here
end

random_policy(s) = rand(ACTIONS)
get_reward(s, a) = REWARD[s]
state_transform(s, a) = @match (s, a) begin 
    (1, _) || (9, _) => s
    _ => s + a
end

begin
    init_play() = env(INIT_STATE, random_policy, get_reward, state_transform)
    get_steps_count() = @> init_play() get_SAR_seq length
    get_final_reward() = @> init_play() get_SAR_seq last last  # TODO: use NamedTuple here
    N = 10000
    steps_samples = convert(Array{Int}, collect(repeatedly(N, get_steps_count)))
    rewards_samples = convert(Array{Int}, collect(repeatedly(N, get_final_reward)))

    bar(counts(steps_samples, maximum(steps_samples)))
    savefig("eve_steps_count.png")
    bar(counts(rewards_samples, maximum(rewards_samples)))
    savefig("eve_reward_count.png")
    println("""Mean of steps: $(mean(steps_samples));
            Mean of rewards: $(mean(rewards_samples))""")
end
# Mean of steps: 15.9168;
# Mean of rewards: 3.78

# ### Day 2 ###
calc_gain(s, γ) = begin
    init_play() = env(s, random_policy, get_reward, state_transform)
    rewards = @>> init_play() get_SAR_seq map(res -> last(res))
    r, n = reduce((temp, r) -> ((g, n) = temp; (g + γ^n * r, n + 1)),  # TODO: use Argument destructuring here
                  (0, 0),
                  rewards)
    r
end

begin
    params = [0.95, 0.98, 1.0]
    plot(layout=@layout([a;b;c]))
    for i in 1:length(params)
        γ = params[i]
        V = zeros(length(REWARD));
        for s in STATES
            V[s] = mean(repeatedly(1000, () -> calc_gain(s, γ)))
        end
        println(V)
        bar!(V, subplot=i, label=latexstring("\\gamma = $(γ)"))
    end
    savefig("eve_v_estimate.png")
end
# [3.0, 2.40616, 2.07831, 2.00239, 2.03833, 2.32305, 2.91446, 3.70394, 5.0]
# [3.0, 2.83945, 2.75356, 2.76483, 2.93804, 3.24011, 3.64397, 4.20483, 5.0]
# [3.0, 3.254, 3.498, 3.736, 3.99, 4.252, 4.558, 4.772, 5.0]

# Value Iteration

function gen_value_iteration(γ)
    function value_iteration(values)
        function calc_V(s)
            maximum(map(a -> get_reward(s, a) + γ * values[state_transform(s, a)],
                        ACTIONS))
        end
        map(calc_V, STATES)
    end
end

function find_stable_value(γ)
    is_terminate(Vₜ, Vₜ₊₁) = maximum(abs.(Vₜ₊₁ - Vₜ)) < 0.1;
    value_iter_fn = gen_value_iteration(γ);
    gen_pair(seq) = zip(seq, tail(seq));
    init_values = zeros(Int, length(STATES))
    
    @>> iterate(value_iter_fn, init_values) begin
        gen_pair
        filter(pair -> is_terminate(pair...))
        first
        first
    end
end

begin
    params = [0.90, 0.95, 0.99]
    plot(layout=@layout([a;b;c]))
    for i in 1:length(params)
        γ = params[i]
        V = find_stable_value(γ)
        println(V)
        bar!(V, subplot=i, label=latexstring("\\gamma = $γ"))
    end
    savefig("eve_v_iteration.png")
end

# Policy Iteration

function policy_evaluation(V, π, γ)
    get_value(s, a) = @match (s, a) begin 
        (1, -1)  => V[1]
        (9, 1) => V[9]
        _ => V[s + a]
    end
    
    reward = [get_reward(sa...) for sa in zip(STATES, π)]
    future_reward = γ * map(s -> get_value(s, π[s]), STATES)
    reward + future_reward
end

function policy_update(V)
    π = [] 
    push!(π, V[1] < V[2] ? 1 : -1)
    for i in 2:8
        push!(π, (V[i - 1] < V[i + 1]) ? 1 : -1)
    end
    push!(π, V[end] < V[end - 1] ? -1 : 1)  # ensure go right at position 5
end

function policy_iter(PV, γ)  # TODO: use argument dispatch here
    πₜ, Vₜ = PV
    println(PV)
    Vₜ₊₁ = policy_evaluation(Vₜ, πₜ, γ)
    πₜ₊₁ = policy_update(Vₜ₊₁)
    πₜ₊₁, Vₜ₊₁ 
end

begin
    V₀ = zeros(Float32, length(STATES))
    π₀ = [random_policy(s) for s in STATES]
    γ = 0.9  # try to change this value
    temp_PV = @>> iterate(PV -> policy_iter(PV, γ), (π₀, V₀)) take(20)
    plot()
    @gif for PV in temp_PV
        π, V = PV
        bar(V, label="V")
        for pair in zip(π, 1:9)
            dir, i = pair
            if dir == -1
                plot!([i, i - 0.5], [0,0], arrow=10, linewidth=5, color = :orange, label = "")
            else
                plot!([i, i + 0.5], [0,0], arrow=10, linewidth=5, color = :blue, label = "")
            end
        end
    end
end