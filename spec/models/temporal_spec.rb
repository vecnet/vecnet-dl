require 'spec_helper'

describe Temporal do
  it "Parses times correctly" do
    t = Temporal.from_s(" 1955 ")
    expect(t.start_time).to eq("1955")
    expect(t.end_time).to eq("1955")

    t = Temporal.from_s(" 1955-")
    expect(t.start_time).to eq("1955")
    expect(t.end_time).to be_nil

    t = Temporal.from_s(" 1955 --")
    expect(t.start_time).to eq("1955")
    expect(t.end_time).to be_nil

    t = Temporal.from_s(" 195505 - 1960")
    expect(t.start_time).to eq("195505")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" 1955-05 - 1960")
    expect(t.start_time).to eq("1955-05")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" 1955-05 -- 1960")
    expect(t.start_time).to eq("1955-05")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" - 19601225")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("19601225")

    t = Temporal.from_s(" - 1960-12-25")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960-12-25")

    t = Temporal.from_s(" -- 1960-12-25")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960-12-25")
  end

  it "decodes from dcsv" do
    t = Temporal.from_dcsv("start=1955")
    expect(t.start_time).to eq("1955")
    expect(t.end_time).to be_nil

    t = Temporal.from_dcsv("start=1955;end=")
    expect(t.start_time).to eq("1955")
    expect(t.end_time).to eq("")

    t = Temporal.from_dcsv("end=1960")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960")
  end
end
