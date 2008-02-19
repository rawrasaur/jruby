require 'test/unit'

# Unit and regression tests for backtraces.
# Note: The tests follow MRI 1.8.6 behavior.
# Behavior of MRI 1.9 is different:
# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/15589
class TestBacktraces < Test::Unit::TestCase
  def setup
    @offset = nil
  end

  # Convenience method to obtain the exception,
  # and to print the stack trace, if needed.
  def get_exception(verbose=false)
    begin
      @get_exception_yield_line = __LINE__ + 1
      yield
    rescue Exception => ex
      puts ex.backtrace.join("\n") if verbose
      ex
    end
  end

  # Main verification method that performs actual checks
  # on the stacktraces.
  def check(expectations, exception)
    backtrace = []
    expectations.strip.split("\n").each { |line|
      line.strip!

      # if line starts with +nnn, we prepend
      # the current file and offset
      md = line.match(/^\+(\d+)(:.*)/)
      if (md)
        flunk("@offset is not defined in the test case") unless @offset
        line = "#{__FILE__}:#{$1.to_i + @offset}#{$2}"
      end

      backtrace << line.strip
    }
    backtrace.each_with_index { |expected, idx|
      assert_equal(expected, exception.backtrace[idx])
    }
  end

  def test_simple_exception
    @offset = __LINE__
    raise RuntimeError.new("Test")
  rescue Exception => ex
    expectation = "+1:in `test_simple_exception'"
    check(expectation, ex)
  end

  def test_exception_from_block
    @offset = __LINE__
    def foo
      yield
    end
    def bar
      yield
    end
    foo { bar { raise TypeError.new("HEH") } }
  rescue Exception => ex
    expectation = %q{
      +7:in `test_exception_from_block'
      +5:in `bar'
      +7:in `test_exception_from_block'
      +2:in `foo'
      +7:in `test_exception_from_block'
    }
    check(expectation, ex)
  end
  
  def test_exception_from_for
    array = [1,2,3,4,5]
    @offset = __LINE__
    for element in array
      raise RuntimeError
    end
  rescue Exception => ex
    expectation = %q{
      +2:in `test_exception_from_for'
      +1:in `each'
      +1:in `test_exception_from_for'
    }
    check(expectation, ex)
  end

  def test_exception_from_proc
    p = Proc.new {
      @offset = __LINE__
      raise StandardError.new
    }
    p.call
  rescue Exception => ex
    expectation = %q{
      +1:in `test_exception_from_proc'
      +3:in `call'
      +3:in `test_exception_from_proc'
    }
    check(expectation, ex)
  end

  def test_exception_from_lambda
    l = lambda {
      @offset = __LINE__
      raise StandardError.new
    }
    l.call
  rescue Exception => ex
    expectation = %q{
      +1:in `test_exception_from_lambda'
      +3:in `call'
      +3:in `test_exception_from_lambda'
    }
    check(expectation, ex)
  end

  def test_exception_from_array_plus
    @offset = __LINE__
    [1,2,3] + 5
  rescue Exception => ex
    expectation = %q{
      +1:in `+'
      +1:in `test_exception_from_array_plus'
    }
    check(expectation, ex)
  end
  
  # JRUBY-2138
  def test_exception_from_string_plus
    @offset = __LINE__
    "hello" + nil
  rescue Exception => ex
    expectation = %q{
      +1:in `+'
      +1:in `test_exception_from_string_plus'
    }
    check(expectation, ex)
  end

  def test_exception_from_string_sub
    @offset = __LINE__
    "hello".sub(/l/, 5)
  rescue Exception => ex
    expectation = %q{
      +1:in `sub'
      +1:in `test_exception_from_string_sub'
    }
    check(expectation, ex)
  end

  def test_zero_devision_exception
    @offset = __LINE__
    1/0
  rescue Exception => ex
    expectation = %q{
      +1:in `/'
      +1:in `test_zero_devision_exception'
    }
    check(expectation, ex)
  end

  def test_exeption_from_object_send
    @offset = __LINE__
    "hello".__send__(:sub, /l/, 5)
  rescue Exception => ex
    expectation = %q{
      +1:in `sub'
      +1:in `__send__'
      +1:in `test_exeption_from_object_send'
    }
    check(expectation, ex)
  end

  def test_arity_exception
    @offset = __LINE__
    "hello".sub
  rescue Exception => ex
    expectation = "+1:in `sub'"
    check(expectation, ex)
  end

  def test_exception_from_eval
    ex = get_exception {
      @offset = __LINE__
      eval("raise RuntimeError.new")
    }
    expectation = %Q{
      +1:in `test_exception_from_eval'
      #{__FILE__}:#{@get_exception_yield_line}:in `eval'
      +1:in `test_exception_from_eval'
      #{__FILE__}:#{@get_exception_yield_line}:in `get_exception'
    }
    check(expectation, ex)
  end

  def test_exception_from_block_inside_eval
    ex = get_exception {
      @offset = __LINE__
      eval("def foo; yield; end; foo { raise RuntimeError.new }")
    }
    expectation = %Q{
      +1:in `test_exception_from_block_inside_eval'
      (eval):1:in `foo'
      (eval):1:in `test_exception_from_block_inside_eval'
      #{__FILE__}:#{@get_exception_yield_line}:in `eval'
      +1:in `test_exception_from_block_inside_eval'
      #{__FILE__}:#{@get_exception_yield_line}:in `get_exception'
    }
    check(expectation, ex)
  end
end
