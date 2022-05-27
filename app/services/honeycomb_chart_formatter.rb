class HoneycombChartFormatter
  attr_accessor :rows

  def initialize(tags)
    @tags = tags.to_a
    @rows = []
    @num_items_so_far = 0
  end

  def format_rows!
    return add_next_n_items_as_row(@tags.count) if only_single_row?
    add_rows_recursively!
  end

  private

  def add_rows_recursively!(num_items_for_row = num_items_in_first_row)
    add_next_n_items_as_row(num_items_for_row)
    return @rows if @tags.empty?
    num_items_remaining = @tags.count
    if @num_items_so_far > num_items_remaining + 1
      add_rows_recursively!(num_items_for_row == 1 ? 1 : num_items_for_row - 1)
    else
      add_rows_recursively!(num_items_for_row + 1)
    end
  end

  def add_next_n_items_as_row(num_items)
    @rows << @tags.shift(num_items)
    @num_items_so_far += num_items
  end

  def num_items_in_first_row
    @tags.count > 39 ? 5 :
      @tags.count > 5 ? 3 : 2
  end

  def only_single_row?
    @tags.count < 3
  end
end


#      * * * 
#     * * * *
#    * * * * *
#   * * * * * *
#  * * * * * * *
#   * * * * * *
#    * * * * *
#     * * * * 
#      * * *

# 7:
#      * * 
#     * * * 
#      * *

# 8:
#      * * 
#     * * * 
#      * * *