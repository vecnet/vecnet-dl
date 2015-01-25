module ReportHelper

  def percent(x, y)
    "n/a" if y == 0
    number_to_percentage(100 * x.to_f / y.to_f, precision: 2)
  end
end
