# Routing table
class RoutingTable
  include Pio

  MAX_NETMASK_LENGTH = 32

  def initialize(route)
    @db = Array.new(MAX_NETMASK_LENGTH + 1) { Hash.new }
    route.each { |each| add(each) }
  end

  def add(options)
    netmask_length = options.fetch(:netmask_length)
    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
    @db[netmask_length][prefix.to_i] = IPv4Address.new(options.fetch(:next_hop))
  end

  def lookup(destination_ip_address)
    MAX_NETMASK_LENGTH.downto(0).each do |each|
      prefix = destination_ip_address.mask(each)
      entry = @db[each][prefix.to_i]
      return entry if entry
    end
    nil
  end
  def showTableEntries()
    tempstr="対象宛先ホスト\t:次の経路\n"
     MAX_NETMASK_LENGTH.downto(0).each do |each|
       @db[each].each_key{|eachkey|
         ipaddr=IPAddr.new(eachkey,Socket::AF_INET)
         tempstr+= ipaddr.to_s+"/"+each.to_s+"\t:"+@db[each][eachkey].to_s+"\n"
       }
    end
    return tempstr
  end

  def delRoutingEntry(nexthost,mask)
    prefix = IPv4Address.new(nexthost).mask(mask).to_i
    @db[mask.to_i].delete(prefix)
  end


end
