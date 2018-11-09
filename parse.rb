#!/usr/bin/env ruby

class Parser
  @@parser||={'CPU_ALL'=>{:handler => :hdr_match},'MEM'=>{:handler => :hdr_match},'MEMNEW'=>{:handler => :hdr_match},'MEMUSE'=>{:handler => :hdr_match},}#'PAGE'=>{:handler=>:hdr_match},'PROC'=>{:handler=>:hdr_match}}
  @@raw_hash, @@clean_hash = {}, {}
  @@l = ''
  @@hdr_ = {}
  #def self.parser; @@parser end
  def self.hdr_match(cat)
    puts "def'd hdr_match for #{cat.inspect}"
    puts "def`d hdr_match for #{@@l.inspect}"
    if @@raw_hash[cat].nil?
      @@raw_hash[cat] = []
      @@hdr_[cat]=@@l.split(/,/) ; @@hdr_[cat].shift
    else
      vals = @@l.split(/,/); vals.shift
      h={}; @@hdr_[cat].each_with_index{|o,i| h[o] = vals[i]}
      @@raw_hash[cat] << h
    end
  end
#handlers = {
  #:hdr_match => Proc.new{|cat|
    #puts "hdr_match called for: #{cat}"
  #}
#}

  def self.parse(fname)
    hdisk_hdr_BBBC,hdr_BBBB,hdr_CPU_ALL,hdr_cpu_N,hdr_MEM,hdr_MEMNEW,hdr_,h = '',nil,nil,nil,nil,{},{}
    ii = 0

    f=File.open(fname,'r')

    f.each_line{|l|
      @@l = l.chomp!

      attrs = @@l.split /,/ ; a0 = attrs[0]
#puts  "#{(attrs.size!=3)? attrs.size : ' '} =  #{attrs.inspect} :: #{ii}"
      case 
        when a0 == 'AAA'
    #AAA,progname,topas_nmon
        m = @@l.match /^AAA,(.+?)[,\s](.+)$/
        k,v = m[1],m[2]
#puts "#{k} :::: #{v}"
        @@raw_hash['AAA'] ||= {};
        @@raw_hash['AAA'][k] = v;

        when a0=='BBBB'
    #BBBB,0000,name,size(GB),disc attach type
        @@raw_hash['BBBB']||=[]
        if (attrs[1] == '0000')
          m = @@l.match(/^BBBB,0000,(.+)$/); hdr_BBBB=m[1].split(/,/)
#puts "#{hdr_BBBB.inspect}"
        else
          m = @@l.match(/^BBBB,\d+,(.+)$/ ); vals=m[1].split(/,/); 
#puts "#{vals.inspect}"
          h={}; hdr_BBBB.each_with_index{|o,i| h[o] = vals[i]}
          @@raw_hash['BBBB'] << h
        end
    #puts "#{m.inspect} :::: m"
        when a0=='BBBC'
        @@raw_hash['BBBC'] ||= {}
        if attrs[2].match(/hdisk\d+:$/)
          hdisk_hdr_BBBC = attrs[2]
          @@raw_hash['BBBC'][ hdisk_hdr_BBBC ] = []
        else
          if attrs[2].split(/\s+/).size != 4
            @@raw_hash['BBBC'][ hdisk_hdr_BBBC ] << attrs[2] ## BBBC,233 : lspv BEGINS, Nr.of cols changes: 5 > 4
          else
            @@raw_hash['BBBC']['lspv'] ||= []; @@raw_hash['BBBC']['lspv'] << attrs[2]
          end
        end  
        when a0=='BBBV'
        @@raw_hash['BBBV'] ||= []
        @@raw_hash['BBBV'] << attrs[2]
#       when a0=='CPU_ALL'
#       if @@raw_hash['CPU_ALL'].nil?
#         @@raw_hash['CPU_ALL'] = []
#         hdr_CPU_ALL=@@l.split(/,/) ; hdr_CPU_ALL.shift
#       else
#         vals = @@l.split(/,/); vals.shift
#         h={}; hdr_CPU_ALL.each_with_index{|o,i| h[o] = vals[i]}
#         @@raw_hash['CPU_ALL'] << h
#       end
        when m = a0.match(/^CPU\d+$/)
        cpu_N=m[0]
        if @@raw_hash[cpu_N].nil?
          @@raw_hash[cpu_N] = []
          if hdr_cpu_N.nil?
            hdr_cpu_N=@@l.split(/,/); hdr_cpu_N.shift; hdr_cpu_N[0]='timelabel';
          end
        else
          vals = @@l.split(/,/); vals.shift
          h={}; hdr_cpu_N.each_with_index{|o,i| h[o] = vals[i]}
          @@raw_hash[cpu_N] << h
        end
#       when a0=='MEM'
#       if @@raw_hash['MEM'].nil?
#         @@raw_hash['MEM'] = []
#         hdr_MEM=@@l.split(/,/) ; hdr_MEM.shift
#       else
#         vals = @@l.split(/,/); vals.shift
#         h={}; hdr_MEM.each_with_index{|o,i| h[o] = vals[i]}
#         @@raw_hash['MEM'] << h
#       end
#       when a0=='MEMNEW'
#       if @@raw_hash['MEMNEW'].nil?
#         @@raw_hash['MEMNEW'] = []
#         hdr_MEMNEW=@@l.split(/,/) ; hdr_MEMNEW.shift
#       else
#         vals = @@l.split(/,/); vals.shift
#         h={}; hdr_MEMNEW.each_with_index{|o,i| h[o] = vals[i]}
#         @@raw_hash['MEMNEW'] << h
#       end
#       when a0=='MEMUSE'
#       if @@raw_hash['MEMUSE'].nil?
#         @@raw_hash['MEMUSE'] = []
#         hdr_['MEMUSE']=@@l.split(/,/) ; hdr_['MEMUSE'].shift
#       else
#         vals = @@l.split(/,/); vals.shift
#         h={}; hdr_['MEMUSE'].each_with_index{|o,i| h[o] = vals[i]}
#         @@raw_hash['MEMUSE'] << h
#       end
      
        when (@@parser.keys.include? a0)
          send @@parser[a0][:handler], a0
        else
        nil

## pk = ["A","B","C","D",/CPU\d+/]
## a0='CPU88'; pk.map{|k| (k.is_a? String)? k==a0 : !a0.match(k).nil?}.any?
##  => true 
## a0='B'; pk.map{|k| (k.is_a? String)? k==a0 : !a0.match(k).nil?}.index(true)
##  => 1 

    ##Parser.parser.each{|cat,v|
    #@@parser.each{|cat,v|
      ##puts ":::: #{handlers[v[:handler]].call(cat)}"
      #send v[:handler], cat
      #send :hdr_match, @@parser
    #}
    ###raise "here;;; at #{ii}; #{@@parser.keys.inspect}"
      end
  
      ii += 1
    }
    puts ii
    f.close
    require 'yaml'
    File.open('parse-result.yml','w'){|f| f.write @@raw_hash.to_yaml }
  end #Parser.parse
end #class Parser


fname=ARGV[0]
raise "'#{fname}': not readable file" unless File.readable? fname

Parser.parse(fname)

