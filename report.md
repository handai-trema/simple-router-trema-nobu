# 課題内容
ルータのCLIをつくる。具体的には以下のコマンドを追加する。
## ルーティングテーブルの表示
## ルーティングテーブルエントリの追加と削除
## ルータのインタフェース一覧の表示

# 解答
## プログラムファイルの説明
今回改良・作成したプログラムは大きく分けて３つのプログラムにわかれている。
まず、
[コマンド実行用プログラム](/bin/simple_router)
は、このrubyプログラムを実行し、サブコマンドのように引数を与えることで各種コマンドを実行できるようにしている。
そのコマンドは稼働中のtremaプロセスの中でプログラムを実行することができる。

次に、
[コントローラプログラム](/lib/simple_router.rb)
は、コントローラが行う動作が記述してある。tremaを実行するときに指定されており、トリガーなどの関数が主にあるが、実行されない関数も記述してあり、上記コマンド実行用プログラムから呼び出されることもある。

最後に、
[ルーティングテーブルプログラム](/lib/routing_table.rb)
ルーティングテーブルクラスのプログラムでは、ルーティングテーブルのデータテーブルを操作するためのプログラムが記述してある。今回、ルーティングテーブルクラスの内部にアクセスする必要のある場合があるので、コントロールプログラムの中のプログラムから呼び出されることがある。

## 機能の実現の説明
### ルーティングテーブルの表示
この機能の実現をするために、ルーティングテーブルクラスのインスタンス変数である@dbの値を参照する。具体的には、下記プログラムのshowTableEntriesで実現する。

まずMAX_NETMASK_LENGTHという定数は32で定義されているが、ロンゲストマッチのルールに則り大きいネットマスク長からdowntoで0まで調べてゆく。これはあとから示されるプログラムでも共通である。eachに、そのマスク長が入る。そしてeach_keyにより@dbのeach番目について全キーに対してループ処理をする。

このときeachkeyにはルーティングを行う対象のホストを表すIPアドレスのプレフィックスの整数化された値が格納されている。IPAddr.newによりipaddrに可読性のあるIPアドレス表記になる。

そして、@db[each][eachkey]にはそのエントリーのしめす、転送先アドレスが格納されている。よってこれらの出力をtempstrに積み重ねていき、最後にreturnで返却をする。

```ruby
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
```
### ルーティングテーブエントリの追加
この機能を追加するためのプログラムは、以下のadd_routing_entryメソッドである。引数に対象となる宛先ホスト名、ネットマスク長、次のホップをとる。
IPアドレスは文字列のままでは渡せないのでIPv4Addressで処理をしたうえで、ルーティングテーブルクラスのメソッドを直接呼び出す。

```ruby
  def add_routing_entry(nexthost,mask,nexthop)
     nexthost=IPv4Address.new(nexthost)
     nexthop =IPv4Address.new(nexthop)
     @routing_table.add({netmask_length:mask.to_i,destination:nexthost,next_hop:nexthop})
  end
```

### ルーティングテーブルエントリの削除
この機能を実現するためには、ルーティングテーブルのデータ@dbから、指定した部分を削除することで実現する。
先ほどと同じく、引数の宛先アドレスの文字列をIPアドレスに変形してから、ネットマスク長で変形したものを整数にすることで、プレフィックスの整数表現を実現する。
その値をキーとして、@db[ネットマスク長]の中からエントリを削除する。プログラムは下のようになる。

```ruby
  def delRoutingEntry(nexthost,mask)
    prefix = IPv4Address.new(nexthost).mask(mask).to_i
    @db[mask.to_i].delete(prefix)
  end
```
### ルータのインタフェース一覧の表示
ルータのインタフェース一覧を表示するためには、Interfaceクラスの中にあり格納されているインタフェーすの情報を読み出す必要がある。
そのため、Interface.all.eachにより、すべてのインタフェースをそれぞれ読む。出力方法としては、各メンバを呼び出すだけである。interface.rb本体を参考にした。

```ruby
  def show_interfaces()
    temptext="MACアドレス\tIPアドレス\tネットマスク長\tポート番号\n"
    Interface.all.each{|each|
      temptext+=each.mac_address.to_s+"\t"+each.ip_address.to_s+"\t"+each.netmask_length.to_s+"\t"+each.port_number.to_s+"\n"
    }
    return temptext
  end
```
## コマンドの呼び出し方の説明
エントリーテーブル一覧表示を行うshowTableEntriesプログラムと、エントリーを削除するdelRoutingEntryプログラムは、エントリーの情報を直接取り扱うため、ルーティングテーブルクラスの記述されているrouting_table.rbの中に記述してあり、その他はコントローラプログラムに記述してある。よって前者２つのプログラムは、コントローラプログラムから呼び出す必要があり、以下のようにコントローラプログラムsimple_router.rbに記述した。
これにより、show_table_entriesとdel_routing_entryを呼び出すことで本体を動かすことができる。

```ruby
  def show_table_entries()
    return @routing_table.showTableEntries
  end  

  def del_routing_entry(nexthost,mask)
    return @routing_table.delRoutingEntry(nexthost,mask)
  end
```

また、コントローラプログラムの中に記述されているメソッドは、以下のように外部プログラムから呼び出すことになる。基本的に、メソッドをよび、その戻り値をそのまま出力するようにしている。内容は前回と同じなので省略する。

```ruby
  desc 'Show routing table'
  arg_name ''
  command :show_rtable do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR
    c.action do |_global_options, options, args|
      result=Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        show_table_entries()
      print(result)
      end
  end

  desc 'Add routing entry'
  arg_name 'nexthost,netmask,nexthop'
  command :add do |c|
    c.desc 'Add new routing entry'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR
    c.action do |_global_options, options, args|
      result=Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        add_routing_entry(args[0],args[1],args[2])
      print result.to_s
    end
  end

  desc 'delete routing entry'
  arg_name 'nexthost,netmask'
  command :del do |c|
    c.desc 'Delete added routing entry by prefix of a destination address'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR
    c.action do |_global_options, options, args|
      Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        del_routing_entry(args[0],args[1])
    end
  end

  desc 'show interfaces'
  arg_name ''
  command :show_iface do |c|
    c.desc 'show all interfaces'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR
    c.action do |_global_options, options, args|
      result =  Trema.trema_process('SimpleRouter', options[:socket_dir]).controller.
        show_interfaces
     print result
    end
  end
```

#実装結果の確認
まず、trema.confの設定を確認する。ホストを１つ増やしている。

```
vswitch('0x1') { dpid 0x1 }
netns('host1') {
  ip '192.168.1.2'
  netmask '255.255.255.0'
  route net: '0.0.0.0', gateway: '192.168.1.1'
}
netns('host2') {
  ip '192.168.2.2'
  netmask '255.255.255.0'
  route net: '0.0.0.0', gateway: '192.168.2.1'
}
netns('host3') {
  ip '192.168.3.2'
  netmask '255.255.255.0'
  route net: '0.0.0.0', gateway: '192.168.3.1'
}

link '0x1', 'host1'
link '0x1', 'host2'
link '0x1', 'host3'
```

## ルーティングテーブルの表示とルーティングテーブルエントリの追加と削除

```
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router show_rtable
対象宛先ホスト	:次の経路
0.0.0.0/0	:192.168.1.2 
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router add 192.168.3.2 24 192.168.1.2
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router show_rtable対象宛先ホスト	:次の経路
192.168.3.0/24	:192.168.1.2
0.0.0.0/0	:192.168.1.2
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router add 192.168.2.2 24 192.168.3.2
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ rema-nobu$ ./bin/simshow_rtable対象宛先ホスト	:次の経路
192.168.3.0/24	:192.168.2.2
192.168.2.0/24	:192.168.3.2
0.0.0.0/0	:192.168.1.2
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router del 192.168.2.2  24
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router show_rtable対象宛先ホスト	:次の経路
192.168.3.0/24	:192.168.2.2
0.0.0.0/0	:192.168.1.2
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router del 192.168.3.2  24
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router show_rtable対象宛先ホスト	:次の経路
0.0.0.0/0	:192.168.1.2
```
このように、addによりルーティングテーブルエントリが追加・削除が成功しており、出力もできている。
## ルータのインタフェース一覧の表示

```
ensyuu2@ensyuu2-VirtualBox:~/simple-router-trema-nobu$ ./bin/simple_router show_iface
MACアドレス	IPアドレス	ネットマスク長	ポート番号
01:01:01:01:01:01	192.168.1.1	24	1
02:02:02:02:02:02	192.168.2.1	24	2
```
このように、各種情報を出力できている。
