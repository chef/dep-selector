#!/usr/bin/env ruby

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

  def generate_clause
    components = deps.inject([[cb_name, version]]){|acc, dep| acc << [dep.cb_name, dep.version] ; acc }
    "ASSERT ( (" + components.map{|comp| "(#{comp.join('=')})"}.join(" AND ") + ") OR (#{cb_name}/=#{version}) );"
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

db.list_keys.each do |cb_name|
  version_nums = []
  db.daterz[cb_name].each do |cb_version|
    version_nums << cb_version.version
    puts cb_version.generate_clause
  end
  puts "ASSERT ( " + version_nums.map{|v| "(#{cb_name}=#{v})" }.join(" OR ") + " );"
end
