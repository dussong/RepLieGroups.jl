# Alternative to the computation of rotation equivariant coupling coefficients

using PartialWaveFunctions
using Combinatorics
using LinearAlgebra

export re_basis_new, ri_basis_new, ind_corr_s1, ind_corr_s2, MatFmi, ML0

function CG(l,m,L,N) 
    M=m[1]+m[2]
    if L[2]<abs(M)
        return 0.
    else
        C=PartialWaveFunctions.clebschgordan(l[1],m[1],l[2],m[2],L[2],M) 
    end
    for k in 3:N
        if L[k]<abs(M+m[k])
            return 0.
        elseif L[k-1]<abs(M)
            return 0.
        else
            C*=PartialWaveFunctions.clebschgordan(L[k-1],M,l[k],m[k],L[k],M+m[k])
            M+=m[k]
        end
    end
    return C
end

function SetLl0(l,N)
    set = Vector{Int64}[]
    for k in abs(l[1]-l[2]):l[1]+l[2]
        push!(set, [0; k])
    end
    for k in 3:N-1
        setL=set
        set=Vector{Int64}[]
        for a in setL
            for b in abs(a[k-1]-l[k]):a[k-1]+l[k]
                push!(set, [a; b])
            end
        end
    end
    setL=set
    set=Vector{Int64}[]
    for a in setL
        if a[N-1]==l[N]
            push!(set, [a; 0])
        end
    end
    return set
end

function SetLl(l,N,L)
    set = Vector{Int64}[]
    for k in abs(l[1]-l[2]):l[1]+l[2]
        push!(set, [0; k])
    end
    for k in 3:N-1
        setL=set
        set=Vector{Int64}[]
        for a in setL
            for b in abs(a[k-1]-l[k]):a[k-1]+l[k]
                push!(set, [a; b])
            end
        end
    end
    setL=set
    set=Vector{Int64}[]
    for a in setL
        if (abs.(a[N-1]-l[N]) <= L)&&(L <= (a[N-1]+l[N]))
            push!(set, [a; L])
        end
    end
    return set
end

# Function that computes the set ML0
function ML0(l,N)
    setML = [[i] for i in -abs(l[1]):abs(l[1])]
    for k in 2:N-1
        set = setML
        setML = Vector{Int64}[]
        for m in set
            append!(setML, [m; lk] for lk in -abs(l[k]):abs(l[k]) )
        end
    end
    setML0=Vector{Int64}[]
    for m in setML
        s=sum(m)
        if  abs(s) < abs(l[N])+1
            push!(setML0, [m; -s])
        end
    end
    return setML0
end

# Function that computes the set ML (relative to equivariance L)
function ML(l,N,L)
    setML = [[i] for i in -abs(l[1]):abs(l[1])]
    for k in 2:N-1
        set = setML
        setML = Vector{Int64}[]
        for m in set
            append!(setML, [m; lk] for lk in -abs(l[k]):abs(l[k]) )
        end
    end
    setML0=Vector{Int64}[]
    for m in setML
        s=sum(m)
        for mn in -L-s:L-s
            if  abs(mn) < abs(l[N])+1
                push!(setML0, [m; mn])
            end
        end
    end
    return setML0
end

function ri_basis_new(l)
    N=size(l,1)
    L=SetLl0(l,N)
    r=size(L,1)
    if r==0 
        return zeros(Float64, 0, 0)
    else 
        setML0=ML0(l,N)
        sizeML0=length(setML0)
        U=zeros(Float64, r, sizeML0)
        M = Vector{Int64}[]
        for (j,m) in enumerate(setML0)
            push!(M,m)
            for i in 1:r
                U[i,j]=CG(l,m,L[i],N)
            end
        end
    end
    return U,M
end

function re_basis_new(l,L)
    N=size(l,1)
    Ll=SetLl(l,N,L)
    r=size(Ll,1)
    if r==0 
        return zeros(Float64, 0, 0)
    else 
        setML0=ML(l,N,L)
        sizeML0=length(setML0)
        U=zeros(Float64, r, sizeML0)
        M = Vector{Int64}[]
        for (j,m) in enumerate(setML0)
            push!(M,m)
            for i in 1:r
                U[i,j]=CG(l,m,Ll[i],N)
            end
        end
    end
    return U,M
end


# Function that computes the permutations that let n and l invariant
function Snl(N,n,l)
    if n==n[1]*ones(N)
        if l==l[1]*ones(N)
            return permutations(1:N)
        end
    end
    if N==1
        return Set([[1]])
    elseif (n[N-1],l[N-1])!=(n[N],l[N])
        S=Set()
        Sn=Snl(N-1,n[1:N-1],l[1:N-1])
        for x in Sn
            append!(x,[N])
            union!(S,Set([x]))
        end
    else
        S=Set()
        k=N
        while (n[k-1],l[k-1])==(n[k],l[k]) && k>2
            k-=1
        end
        if k==2 && (n[1],l[1])==(n[2],l[2])
            return Set(permutations(1:N))
        else
            Sn=Snl(k-1,n[1:k-1],l[1:k-1])
            for x in Sn
                for s in Set(permutations(k:N))
                    y=copy(x)
                    append!(y,s)
                    union!(S,Set([y]))
                end
            end
        end
    end
    return S
end


#Function that computes the set of classes using the set Ml0 and the possible permutations
function class(setML0,sigma,N,l)
    setclass=Vector{Vector{Int64}}[]
    pop!(setML0,zeros(Int64,N))
    while setML0!=Set()
        x=pop!(setML0)
        p=[x]
        for s in sigma
            y=x[s]
            if y in setML0
                append!(p,[y])
                pop!(setML0,y)
            end
        end
        append!(setclass,[p])
    end
    setclasses=Vector{Vector{Int64}}[]
    for x in setclass
        for y in setclass
            if x==y
                if minimum(x)==minimum(-x)
                    if iseven(sum(l))
                        append!(setclasses,[x])
                    end
                end
            elseif minimum(x)==minimum(-y)
                if y<x
                    append!(setclasses,[x])
                end
            end
        end
    end
    if iseven(sum(l))
        append!(setclasses,[[zeros(N)]])
    end
    setclasses
end



# Function that computes the matrix ( f(m,i) )
function MatFmi(n,l)
    N=size(l,1)
    L=SetLl0(l,N)
    r=size(L,1)
    if r==0 
        return zeros(Float64, 0, 0)
    else 
        ML00 = ML0(l,N)
        setML0=Set(ML00)
        sigma = Snl(N,n,l)
        setclass=class(setML0,sigma,N,l)
        sizeML0=length(setclass)
        Matrix=zeros(Float64, r, sizeML0)
        for i in 1:r
            for j in 1:sizeML0
                for m in setclass[j]
                    Matrix[i,j]+=CG(l,m,L[i],N)
                end
            end
        end
    end
    return Matrix, ML00
end