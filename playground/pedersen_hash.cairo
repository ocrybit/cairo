# The following code implements a Pedersen hash chain.
# Given the [Pedersen hash](https://docs.starkware.co/starkex-docs/crypto/pedersen-hash-function) function `H`, which
# takes two field elements and returns one representing their hash,
# a hash chain on inputs x_0, x_1, ..., x_n is the result of
# H(H(...H(H(x_0, x_1), x_2), ...,x_{n-1}), x_n)
# For example, the hash chain of (1, 2, 3, 4) is H(H(H(1, 2), 3), 4).
#
# Fix the function `hash_chain` to correctly implement the
# hash chain. Run your code to test it.
#
# Note: Don't use starkware.cairo.common.hash_chain (it computes the chain differently).

# Use the pedersen builtin.
%builtins pedersen

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import pedersen_hash

# Computes the Pedersen hash chain on an array of size `length` starting from `data_ptr`.
func hash_chain(pedersen_ptr : HashBuiltin*, data_ptr : felt*, length : felt) -> (
        pedersen_ptr : HashBuiltin*, result : felt):
    if length == 2:
       pedersen_hash(pedersen_ptr=pedersen_ptr, x=[data_ptr], y=[data_ptr + 1])
        return (...)
    else:
        # Fix here:
        let (pedersen_ptr, result) = hash_chain(pedersen_ptr, data_ptr, length - 1)
        pedersen_hash(pedersen_ptr=pedersen_ptr, x=result, y=[data_ptr + (length - 1)])
        return (...)
    end
end

func main(pedersen_ptr : HashBuiltin*) -> (pedersen_ptr : HashBuiltin*):
    alloc_locals
    # Allocate a new array.
    let (local data_ptr : felt*) = alloc()
    # Fill the new array with field elements.
    assert [data_ptr] = 314
    assert [data_ptr + 1] = 159
    # Run the hash chain.
    let (pedersen_ptr, result) = hash_chain(pedersen_ptr=pedersen_ptr, data_ptr=data_ptr, length=2)
    # Check the result.
    assert result = 307958720726328212653290369969069617958360335228383070119367204176047090109

    # Fill two more cells in the array.
    assert [data_ptr + 2] = 265
    assert [data_ptr + 3] = 358
    # Compute the hash chain on all four cells.
    let (pedersen_ptr, result) = hash_chain(pedersen_ptr=pedersen_ptr, data_ptr=data_ptr, length=4)
    assert result = 1828757374677754028678056220799392919487521050857166686061558043629802016816

    return (pedersen_ptr=pedersen_ptr)
end
