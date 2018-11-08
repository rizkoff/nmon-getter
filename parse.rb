#!/usr/bin/env ruby

#STDOUT.printf("#{ARGV[0].inspect}");
fname=ARGV[0]
raise "THE FILE '#{fname}' is not a readable file, EXITING!" unless File.readable? fname

raw_hash, clean_hash = {}, {}
hdisk_hdr_BBBC,hdr_BBBB,h = '',nil,{}
ii = 0

f=File.open(fname,'r')

f.each_line{|l|
  l.chomp!

  attrs = l.split /,/ ; a0 = attrs[0]
#puts  "#{(attrs.size!=3)? attrs.size : ' '} =  #{attrs.inspect} :: #{ii}"
  case 
    when a0 == 'AAA'
    #AAA,progname,topas_nmon
    m = l.match /^AAA,(.+?)[,\s](.+)$/
    k,v = m[1],m[2]
#puts "#{k} :::: #{v}"
    raw_hash['AAA'] ||= {};
    raw_hash['AAA'][k] = v;

    when a0=='BBBB'
    #BBBB,0000,name,size(GB),disc attach type
    raw_hash['BBBB']||=[]
    if (attrs[1] == '0000')
      m = l.match(/^BBBB,0000,(.+)$/); hdr_BBBB=m[1].split(/,/)
#puts "#{hdr_BBBB.inspect}"
    else
      m = l.match(/^BBBB,\d+,(.+)$/ ); vals=m[1].split(/,/); 
#puts "#{vals.inspect}"
      h={}; hdr_BBBB.each_with_index{|o,i| h[o] = vals[i]}
      raw_hash['BBBB'] << h
    end
    #puts "#{m.inspect} :::: m"
    when a0=='BBBC'
    raw_hash['BBBC'] ||= {}
    if attrs[2].match(/hdisk\d+:$/)
      hdisk_hdr_BBBC = attrs[2]
      raw_hash['BBBC'][ hdisk_hdr_BBBC ] = []
    else
      if attrs[2].split(/\s+/).size != 4
        raw_hash['BBBC'][ hdisk_hdr_BBBC ] << attrs[2] ## BBBC,233 : lspv BEGINS, Nr.of cols changes: 5 > 4
      else
        raw_hash['BBBC']['lspv'] ||= []; raw_hash['BBBC']['lspv'] << attrs[2]
      end
    end  
  end
  
  ii += 1
  break unless ['AAA','BBBB','BBBC'].include? attrs[0]
}
puts raw_hash['BBBC']['lspv'].inspect
puts ii
f.close
