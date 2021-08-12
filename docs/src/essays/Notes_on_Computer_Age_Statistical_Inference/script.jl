using CSV
using Plots
using StatPlots
using DataFrames
using GLM

gr()
cd(raw"D:\workspace\github\blog-py\blog\static\essay_resources\Notes_on_Computer_Age_Statistical_Inference") 

kidney = CSV.read("kidney.csv", nullable=false)
@df kidney scatter(:age, :Tot)

X = hcat(ones(nrow(kidney)), kidney[:age])
y = kidney[:Tot]
OLS = fit(LinearModel, X, y)
# GLM.LinearModel{GLM.LmResp{Array{Float64,1}},GLM.DensePredChol{Float64,Base.LinAlg.Cholesky{Float64,Array{Float64,2}}}}:

# Coefficients:
#        Estimate Std.Error  t value Pr(>|t|)
# x1      2.86067  0.359561  7.95603   <1e-12
# x2   -0.0786009 0.0090557 -8.67972   <1e-14

age_samples = collect(20:10:90)
Xtest = hcat(ones(length(age_samples)), age_samples)
pred = predict(OLS, Xtest, :confint)

for i in 1:size(pred, 1)
    y_pred, y_lower, y_upper = pred[i, :]
    display(plot!([age_samples[i],age_samples[i]], [ y_lower, y_upper], linewidth = 3))
end

plot!(age_samples[[1, end]], pred[[1, end], 1], legend=:none, linewidth=3)
savefig("Figure_1_1.png")