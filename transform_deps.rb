#!/usr/bin/env ruby

require 'rubygems'
require 'gecoder'

OR_TERM = "OR"
AND_TERM = "AND"
EQL_TERM = "="
NE_TERM = "/="

class Dep
  attr_accessor :cb_name, :version
  
  def initialize(cb)
    @cb_name = cb.cb_name
    @version = cb.version
  end
end

class CBVersion
  attr_accessor :cb_name, :version, :deps
  
  def initialize(cb_name, version, deps=[])
    @cb_name = cb_name
    @version = version
    @deps = deps
  end

  def generate_clause(cb_to_model_var)
    components = deps.inject([[cb_name, version]]){|acc, dep| acc << [dep.cb_name, dep.version] ; acc }
    conjuction = components.inject(cb_to_model_var[cb_name].must == version) do |acc, comp|
      acc & (cb_to_model_var[comp.first].must == comp.last)
    end
    conjuction | (cb_to_model_var[cb_name].must_not == version)
  end
end

class DB
  attr_accessor :daterz

  def initialize
    @daterz = {}
  end
  
  def insert(cb_name, version, deps=[])
    cb = CBVersion.new(cb_name, version, deps)
    (@daterz[cb_name] ||=[]) << cb
    cb
  end

  def list_keys
    @daterz.keys
  end
end

db = DB.new
b1 = db.insert("b", 1)
b2 = db.insert("b", 2)
c1 = db.insert("c", 1)
a1 = db.insert("a", 1, [Dep.new(b2)])
a2 = db.insert("a", 2, [Dep.new(b1),Dep.new(c1)])

model = Gecode::Model.new
cb_to_model_var = db.list_keys.inject({}) do |acc, cb_name|
  acc[cb_name] = model.int_var(db.daterz[cb_name].map{|cb_version| cb_version.version})
  model.branch_on acc[cb_name]#, :value => :max
  acc
end

db.list_keys.each do |cb_name|
  db.daterz[cb_name].each do |cb_version|
    cb_version.generate_clause(cb_to_model_var)
  end
end

soln = model.solve!
cb_to_model_var.each_pair{|cb_name, var| puts "#{cb_name}: #{var.value}"}
