%builtins output

from starkware.cairo.common.alloc import alloc

func array_prod(arr, size) -> (prod):
    if size == 0:
        return (prod=1)
    end

    let (prod_of_rest) = array_prod(arr=arr + 2, size=size - 2)
    return (prod=[arr] * prod_of_rest)
end

func main(output_ptr) -> (output_ptr):
    const ARRAY_SIZE = 6

    let (ptr) = alloc()

    assert [ptr] = 1
    assert [ptr + 1] = 2
    assert [ptr + 2] = 3
    assert [ptr + 3] = 4
    assert [ptr + 4] = 5
    assert [ptr + 5] = 6

    let (prod) = array_prod(arr=ptr + 1, size=ARRAY_SIZE - 1)

    assert [output_ptr] = prod

    return (output_ptr=output_ptr + 1)
end