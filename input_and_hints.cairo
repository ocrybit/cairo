%builtins output range_check
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc

struct KeyValue:
    member key = 0
    member value = 1
    const SIZE = 2
end

# Builds a DictAccess list for the computation of the cumulative
# sum for each key.
func build_dict(
    list : KeyValue*,
    size,
    dict : DictAccess*
) -> (dict : DictAccess*):
    if size == 0:
        return (dict=dict)
    end
    
    %{
        if ids.list.key not in cumulative_sums:
            cumulative_sums[ids.list.key] = 0
        # Populate ids.dict.prev_value using cumulative_sums...
        ids.dict.prev_value = cumulative_sums[ids.list.key]
        # Add list.value to cumulative_sums[list.key]...
        cumulative_sums[ids.list.key] += ids.list.value
    %}
    
    # Copy list.key to dict.key...
    assert dict.key = list.key
    # Verify that dict.new_value = dict.prev_value + list.value...
    assert dict.new_value = dict.prev_value + list.value
    # Call recursively to build_dict()...
    build_dict(list + KeyValue.SIZE, size - 1, dict + DictAccess.SIZE)
    return (...)
end

# Verifies that the initial values were 0, and writes the final
# values to result.
func verify_and_output_squashed_dict(
    output_ptr : felt*,
    squashed_dict : DictAccess*,
    squashed_dict_end : DictAccess*,
    result : KeyValue*
) -> (result : KeyValue*):
    alloc_locals
    tempvar diff = squashed_dict_end - squashed_dict
    if diff == 0:
        return (result=result)
    end

    local idx
    %{
        ids.idx = idx
        idx += 1  
    %}

    # Verify prev_value is 0...
    assert squashed_dict.prev_value = 0
    # Copy key to result.key...
    assert result.key = squashed_dict.key
    # Copy new_value to result.value...
    assert result.value = squashed_dict.new_value
    # Call recursively to verify_and_output_squashed_dict...
    assert [output_ptr + idx * 2] = result.key
    assert [output_ptr + idx * 2 + 1] = result.value
    verify_and_output_squashed_dict(
        output_ptr=output_ptr,
        squashed_dict=squashed_dict + DictAccess.SIZE,
        squashed_dict_end=squashed_dict_end,
        result=result+KeyValue.SIZE
    )
    return (...)
end

# Given a list of KeyValue, sums the values, grouped by key,
# and returns a list of pairs (key, sum_of_values).
func sum_by_key(
    output_ptr : felt*, range_check_ptr, list : KeyValue*, size
) -> (range_check_ptr, result : KeyValue*, result_size):
    alloc_locals
    %{
        # Initialize cumulative_sums with an empty dictionary.
        # This variable will be used by ``build_dict`` to hold
        # the current sum for each key.
        cumulative_sums = {}
        idx = 0
    %}

    # Allocate memory for dict, squashed_dict and res...
    let (dict_start) = alloc()
    local dict_start : DictAccess* = dict_start
    let (squashed_dict) = alloc()
    local squashed_dict : DictAccess* = squashed_dict
    let (res) = alloc()
    local res : KeyValue* = res
    
    # Call build_dict()...
    let (dict_end) = build_dict(
        list=list,
        size=size,
        dict=dict_start
    )
    
    # Call squash_dict()...
    let (local range_check_ptr, squashed_dict_end : DictAccess*) = squash_dict(
        range_check_ptr=range_check_ptr,
        dict_accesses=dict_start,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict
    )
    local result_size = (squashed_dict_end - squashed_dict) / DictAccess.SIZE

    # Call verify_and_output_squashed_dict()...
    verify_and_output_squashed_dict(
        output_ptr=output_ptr,
        squashed_dict=squashed_dict,
        squashed_dict_end=squashed_dict_end,
        result=res)
    return (range_check_ptr, res, result_size)
end

func main(output_ptr : felt*, range_check_ptr) -> (output_ptr : felt*, range_check_ptr):
    alloc_locals
    
    let (dict_start) = alloc()
    local dict_start : DictAccess* = dict_start
    
    local list0 : KeyValue
    assert list0.key = 3
    assert list0.value = 5
    
    local list1 : KeyValue
    assert list1.key = 1
    assert list1.value = 10
    
    local list1 : KeyValue
    assert list1.key = 3
    assert list1.value = 1
    
    local list1 : KeyValue
    assert list1.key = 3
    assert list1.value = 8
    
    local list1 : KeyValue
    assert list1.key = 1
    assert list1.value = 20
    
    let (__fp__, _) = get_fp_and_pc()
    let (range_check_ptr, result, result_size) = sum_by_key(
        output_ptr=output_ptr,
        range_check_ptr=range_check_ptr,
        list=&list0,
        size=5)

    return (output_ptr=output_ptr + result_size * 2, range_check_ptr=range_check_ptr)
end