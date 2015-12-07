(function($){
  // Instructions: http://phrogz.net/jquery-bind-delayed-get
  // Copyright:    Gavin Kistner, !@phrogz.net
  // License:      http://phrogz.net/js/_ReuseLicense.txt
  var defaults = {
    events:'keyup change',
    delay:250, // milliseconds
    url:null,
    callback:null,
    data:{}, // may be function or literal data
    dataType:'json',
    type:'get',
    resendDuplicates:true
  };
  $.fn.bindDelayed = function(opts){
    if (!opts) opts={};
    for (var field in defaults) if (!(field in opts)) opts[field] = defaults[field];
    var xhr, timer, ct=0, lastDataString;
    return this.on(opts.events,function(){
      var element = this;
      var newData = opts.data && (typeof opts.data == 'function' ? opts.data.call(element) : opts.data);
      var newDataString = JSON.stringify(newData)
      if (!opts.resendDuplicates && (lastDataString==newDataString)) return;
      lastDataString = newDataString;
      clearTimeout(timer);
      if (xhr) xhr.abort();
      timer = setTimeout(function(){
        var id = ++ct;
        xhr = $.ajax({
          type:opts.type,
          url:opts.url,
          data:newData,
          dataType:opts.dataType,
          success:function(data){
            xhr = null;
            if (id==ct && opts.callback) opts.callback.call(this,data);
          }
        });
      },opts.delay);
    });
  };
})(jQuery);