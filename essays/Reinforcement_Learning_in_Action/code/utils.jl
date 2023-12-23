using Lazy
import Base:convert, colon

takeuntil(pred::Function, l::List) = 
    @lazy isempty(l) ? [] :
        pred(first(l)) ? [first(l)] : first(l):takeuntil(pred, tail(l))

colon(x::List, xs::List) = prepend(x, xs)