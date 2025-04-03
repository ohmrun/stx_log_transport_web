package stx.log.transport.web;


import haxe.io.Bytes;
using tink.CoreApi;
using stx.Pico;
using eu.ohmrun.Stig;
using eu.ohmrun.Datura;
using stx.Log;
using stx.Fail;
using stx.Coroutine;
using stx.coroutine.Core;


class Client{
  static public function main(){
    trace("main");
    final client = new DaturaClient().source(
      () -> __.success(Client_Config(DaturaOptions.unit()))
    ).emiter(
      (_:Nada) -> Client_Exception(__.fault().of(E_Datura_UnexpectedEndCondition))
    );
    function driver(self:Emiter<DaturaClientMessage,DaturaFailure>):Emiter<DaturaClientMessage,DaturaFailure>{
      trace(self);
      return switch(self){
        case Emit(Client_Error(client, reason), next) :
          __.halt(__.fault().of(E_Datura(reason)));
        case Emit(Client_Ready(client),next) : 
          trace("ready");
          final data = Stig.instance.encode(
            { a: 1, b : "2", c : true , d : [1,2,3,4,5], e : ["this" => { ok : true }]}
          ).toStigForm().toJson();

          client.sendChunk(Bytes.ofString(data));
          next.app(driver);
          // next;
        default : self;//x.app(driver);
      }
    }
    final future = client.app(driver).asEmiter().pocket(
      x -> {}
    ).run();
    
    future.handle(
      o -> o.fold(
        x -> {
          Console.log(x);
        },
        () -> {}
      )
    );
  }
}