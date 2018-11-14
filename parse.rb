#!/usr/bin/env ruby

require 'yaml'
class Parser
  @@parser||={
    ['AAA']=>{:handler=>:key_value,:opts=>{:pattern => /^(AAA),(.+?)[,\s](.+)$/}},
    ['BBBL']=>{:handler=>:key_value,:opts=>{:excl => 0, :pattern => /^([^,]+),(.+?),(.+?)(?:,(.+))?$/}},  # /^([^,]+),(.+?),(.+?),(.+)$/
    ['BBBB','BBBN','BBBD']=>{:handler=>:hdr_match,:opts=>{:excl => 0, :pattern_skip=>/^BBBD,000,/}},
    ['BBBC']=>{:handler=>:fill_hash,:opts=>{:idx => 1, :pattern => /hdisk\d+:$/}},
    ['BBBV','BBBP']=>{:handler => :fill_array, :opts=>{:excl => 0, :pattern => /([^,]+),?/}},
    ['CPU_ALL','MEM','MEMNEW','MEMUSE','PAGE','PROC','FILE','NET','NETPACKET','NETSIZE','NETERROR','DISKBUSY','DISKREAD','DISKWRITE','DISKXFER','DISKRXFER','DISKBSIZE','DISKRIO','DISKWIO','DISKAVGRIO','DISKAVGWIO','IOADAPT','JFSFILE','JFSINODE']=>{:handler => :hdr_match},
    [/^CPU\d+$/]=>{:handler => :hdr_match,:opts=>{:hdr_categ => 'timelabel'}}
  }
  @@raw_hash, @@clean_hash, @@hdr_ = {}, {}, {}
  @@l = ''
  def self.raw_hash; @@raw_hash; end
 
  def self.hdr_match(opts={})
    la = @@l.split(/,/); categ = la.shift;
    return if opts[:pattern_skip] && @@l.match(opts[:pattern_skip])
    la.delete_at(opts[:excl]) if opts[:excl]
    hdr_categ = opts[:hdr_categ] || categ
    if @@raw_hash[categ].nil?
      @@raw_hash[categ] = []
      if @@hdr_[hdr_categ].nil?
        @@hdr_[hdr_categ] = la
        @@hdr_[hdr_categ][0] = opts[:hdr_categ] if opts[:hdr_categ]
      end
    else
      h={}; @@hdr_[hdr_categ].each_with_index{|o,i| h[o] = la[i]}
      @@raw_hash[categ] << h
    end
  end
  def self.fill_array(opts={})
    la = @@l.scan(opts[:pattern]).flatten; categ = la.shift
    la.delete_at(opts[:excl]) if opts[:excl]
    @@raw_hash[categ] ||= []
    @@raw_hash[categ] << la.join(',')
  end
  def self.fill_hash(opts={})
    idx = opts[:idx]; pattern = opts[:pattern]
    la = @@l.split(/,/); categ = la.shift
    @@raw_hash[categ] ||= {}
    if la[idx].match(pattern)
      @@hdr_[categ] = la[idx]
      @@raw_hash[categ][ @@hdr_[categ] ] = []
    else
      @@raw_hash[categ][ @@hdr_[categ] ] << la[idx] ##BBBC,233 : lspv BEGINS, Nr.of cols changes: 5 > 4
    end
  end
  def self.key_value(opts={})
    pattern = opts[:pattern]
    la = @@l.scan(pattern)[0]; categ = la.shift
    la.delete_at(opts[:excl]) if opts[:excl]
    @@raw_hash[categ] ||= {}
    @@raw_hash[categ][la[0]] = la[1]
  end

  def self.parse(fname)
    @@ii=0
    f=File.open(fname,'r')
    f.each_line{|l|
      @@ii+=1
      @@l = l.chomp!; attrs = @@l.split /,/ ; a0 = attrs[0]

      @@parser.each{|ka,v|
        if ka.map{|k| (k.is_a? String)? k==a0 : !a0.match(k).nil? }.any? ## {}.index(true)
          send v[:handler], v[:opts] || {}
          break
        end
      }
    }
    f.close
  end #Parser.parse
end #class Parser

fname=ARGV[0]; raise "'#{fname}': not readable file" unless File.readable? fname

Parser.parse(fname)
File.open('parse-result.yml','w'){|f| f.write Parser.raw_hash.to_yaml }

