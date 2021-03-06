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

    t = Temporal.from_s(" 1955-05 - 1960")
    expect(t.start_time).to eq("1955-05")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" 1955-5 - 1960")
    expect(t.start_time).to eq("1955-5")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s("2010-2011")
    expect(t.start_time).to eq("2010")
    expect(t.end_time).to eq("2011")

    t = Temporal.from_s(" 1955-05-1960")
    expect(t.start_time).to eq("1955-05")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" 1955-05 -- 1960")
    expect(t.start_time).to eq("1955-05")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" 1955-5-1960")
    expect(t.start_time).to eq("1955-5")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" 1955-5 -- 1960")
    expect(t.start_time).to eq("1955-5")
    expect(t.end_time).to eq("1960")

    t = Temporal.from_s(" - 1960-12-25")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960-12-25")

    t = Temporal.from_s("-1960-12-25")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960-12-25")

    t = Temporal.from_s("--1960-12-25")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960-12-25")

    t = Temporal.from_s("--1960-02-25")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960-02-25")

    t = Temporal.from_s("--1960-2-25")
    expect(t.start_time).to be_nil
    expect(t.end_time).to eq("1960-2-25")
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
