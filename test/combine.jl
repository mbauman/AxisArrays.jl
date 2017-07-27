# cat
A1data, A2data = [1 3; 2 4], [5 7; 6 8]

A1 = AxisArray(A1data, Axis{:Row}([:First, :Second]), Axis{:Col}([:A, :B]))
A2 = AxisArray(A2data, Axis{:Row}([:Third, :Fourth]), Axis{:Col}([:A, :B]))
@test isa(cat(1, A1, A2), AxisArray)
@test cat(1, A1, A2) == AxisArray(vcat(A1data, A2data),
                                  Axis{:Row}([:First, :Second, :Third, :Fourth]), Axis{:Col}([:A, :B]))

A2 = AxisArray(A2data, Axis{:Row}([:First, :Second]), Axis{:Col}([:C, :D]))
@test isa(cat(2, A1, A2), AxisArray)
@test cat(2, A1, A2) == AxisArray(hcat(A1data, A2data),
                                  Axis{:Row}([:First, :Second]), Axis{:Col}([:A, :B, :C, :D]))

A2 = AxisArray(A2data, Axis{:Row}([:First, :Second]), Axis{:Col}([:A, :B]))
@test isa(cat(3, A1, A2), AxisArray)
@test cat(3, A1, A2) == AxisArray(cat(3, A1data, A2data),
                                       Axis{:Row}([:First, :Second]), Axis{:Col}([:A, :B]),
                                       Axis{:page}(1:2))

A1 = AxisArray(A1data, :Row, :Col)
A2 = AxisArray(A2data, :Row, :Col)
@test_throws ArgumentError cat(2, A1, A2)
@test cat(3, A1, A2) == AxisArray(cat(3, A1data, A2data), :Row, :Col)

# merge
Adata, Bdata, Cdata = randn(4,4,2), randn(4,4,2), randn(4,4,2)
A = AxisArray(Adata, Axis{:X}([1,2,3,4]), Axis{:Y}([10.,20,30,40]), Axis{:Z}([:First, :Second]))
B = AxisArray(Bdata, Axis{:X}([3,4,5,6]), Axis{:Y}([30.,40,50,60]), Axis{:Z}([:First, :Second]))

ABdata = zeros(6,6,2)
ABdata[1:4,1:4,:] = Adata
ABdata[3:6,3:6,:] = Bdata
@test merge(A,B) == AxisArray(ABdata, Axis{:X}([1,2,3,4,5,6]), Axis{:Y}([10.,20,30,40,50,60]), Axis{:Z}([:First, :Second]))

AC = AxisArray(cat(3, Adata, Cdata), :X, :Y, :Z)
B2 = AxisArray(Bdata, :X, :Y, :Z)
@test merge(AC,B2) == AxisArray(cat(3, Bdata, Cdata), :X, :Y, :Z)

# join
ABdata = zeros(6,6,2,2)
ABdata[1:4,1:4,:,1] = Adata
ABdata[3:6,3:6,:,2] = Bdata
@test join(A,B) == AxisArray(ABdata, Axis{:X}([1,2,3,4,5,6]), Axis{:Y}([10.,20,30,40,50,60]), Axis{:Z}([:First, :Second]))
@test join(A,B, newaxis=Axis{:JoinAxis}([:A, :B])) == AxisArray(ABdata, Axis{:X}([1,2,3,4,5,6]), Axis{:Y}([10.,20,30,40,50,60]), Axis{:Z}([:First, :Second]), Axis{:JoinAxis}([:A, :B]))
@test join(A,B,method=:inner) == AxisArray(ABdata[3:4, 3:4, :, :], Axis{:X}([3,4]), Axis{:Y}([30.,40]), Axis{:Z}([:First, :Second]))
@test join(A,B,method=:left) == AxisArray(ABdata[1:4, 1:4, :, :], A.axes...)
@test join(A,B,method=:right) == AxisArray(ABdata[3:6, 3:6, :, :], B.axes...)
@test join(A,B,method=:outer) == join(A,B)

# flatten
A1 = AxisArray(A1data, Axis{:X}(1:2), Axis{:Y}(1:2))
A2 = AxisArray(reshape(A2data, size(A2data)..., 1), Axis{:X}(1:2), Axis{:Y}(1:2), Axis{:Z}([:foo]))

@test @inferred(flatten(Val{2}, A1, A2)) == AxisArray(cat(3, A1data, A2data), Axis{:X}(1:2), Axis{:Y}(1:2), Axis{:flat}(CategoricalVector([(1,), (2, :foo)])))
@test @inferred(flatten(Val{2}, A1)) == AxisArray(reshape(A1, 2, 2, 1), Axis{:X}(1:2), Axis{:Y}(1:2), Axis{:flat}(CategoricalVector([(1,)])))
@test @inferred(flatten(Val{2}, A1)) == AxisArray(reshape(A1.data, size(A1)..., 1), axes(A1)..., Axis{:flat}(CategoricalVector([(1,)])))

@test @inferred(flatten(Val{2}, (:A1, :A2), A1, A2)) == AxisArray(cat(3, A1data, A2data), Axis{:X}(1:2), Axis{:Y}(1:2), Axis{:flat}(CategoricalVector([(:A1,), (:A2, :foo)])))
@test @inferred(flatten(Val{2}, (:foo,), A1)) == AxisArray(reshape(A1, 2, 2, 1), Axis{:X}(1:2), Axis{:Y}(1:2), Axis{:flat}(CategoricalVector([(:foo,)])))
@test @inferred(flatten(Val{2}, (:a,), A1)) == AxisArray(reshape(A1.data, size(A1)..., 1), axes(A1)..., Axis{:flat}(CategoricalVector([(:a,)])))

@test @inferred(flatten(Val{0}, A1)) == AxisArray(vec(A1data), Axis{:flat}(CategoricalVector(collect(IterTools.product((1,), axisvalues(A1)...)))))
@test @inferred(flatten(Val{1}, A1)) == AxisArray(A1data, Axis{:row}(1:2), Axis{:flat}(CategoricalVector(collect(IterTools.product((1,), axisvalues(A1)[2])))))
@test @inferred(flatten(Val{1}, (1,), A1)) == flatten(Val{1}, A1)
@test @inferred(flatten(Val{1}, Array{Int, 2}, A1)) == flatten(Val{1}, A1)
@test @inferred(flatten(Val{1}, Array{Int, 2}, (1,), A1)) == flatten(Val{1}, A1)

@test_throws ArgumentError flatten(Val{-1}, A1)
@test_throws ArgumentError flatten(Val{10}, A1)

A1ᵀ = transpose(A1)
@test_throws ArgumentError flatten(Val{-1}, A1, A1ᵀ)
@test_throws ArgumentError flatten(Val{1}, A1, A1ᵀ)
@test_throws ArgumentError flatten(Val{10}, A1, A1ᵀ)
