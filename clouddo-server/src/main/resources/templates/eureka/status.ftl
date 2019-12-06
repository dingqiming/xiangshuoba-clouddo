<#import "/spring.ftl" as spring />
<!doctype html>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->
  <head>
    <base href="<@spring.url basePath/>">
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Eureka</title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width">

    <link rel="stylesheet" href="eureka/css/wro.css">

  </head>

  <body id="one">
    <#include "header.ftl">
    <div class="container-fluid xd-container">
      <#include "navbar.ftl">
      <h1>Instances currently registered with Eureka</h1>
      <table id='instances' class="table table-striped table-hover">
        <thead>
          <tr><th>Application</th><th>AMIs</th><th>Availability Zones</th><th>Status</th></tr>
        </thead>
        <tbody>
          <#if apps?has_content>
            <#list apps as app>
              <tr>
                <td><b>${app.name}</b></td>
                <td>
                  <#list app.amiCounts as amiCount>
                    <b>${amiCount.key}</b> (${amiCount.value})<#if amiCount_has_next>,</#if>
                  </#list>
                </td>
                <td>
                  <#list app.zoneCounts as zoneCount>
                    <b>${zoneCount.key}</b> (${zoneCount.value})<#if zoneCount_has_next>,</#if>
                  </#list>
                </td>
                <td>
                  <#list app.instanceInfos as instanceInfo>
                    <#if instanceInfo.isNotUp>
                      <font color=red size=+1><b>
                    </#if>
                    <b>${instanceInfo.status}</b> (${instanceInfo.instances?size}) -
                    <#if instanceInfo.isNotUp>
                      </b></font>
                    </#if>
                    <#list instanceInfo.instances as instance>
                        <div>
                        <#if instanceInfo.status =="OUT_OF_SERVICE">
                            <font color=red ><b>服务已下线</b></font>
                         </#if>
                          <#if instance.isHref>
                            <a href="${instance.url}" target="_blank">${instance.id}</a>
                            <a href="/eureka/apps/${app.name}/${instance.id}" target="_blank">详情</a>
                            <a onclick="deleteInstance('${app.name}','${instance.id}')"  style="cursor:pointer;">删除</a>
                            <a onclick="outInstance('${app.name}','${instance.id}')"  style="cursor:pointer;">下线</a>
                            <a onclick="upInstance('${app.name}','${instance.id}')"  style="cursor:pointer;">上线</a>
                          <#else>
                            ${instance.id}
                          </#if><#if instance_has_next>,</#if>
                        </div>
                    </#list>

                  </#list>
                </td>
              </tr>
            </#list>
          <#else>
            <tr><td colspan="4">No instances available</td></tr>
          </#if>

        </tbody>
      </table>
        <div>备注：将某个实例设置为下线，这个和删除不同，如果你手动调用删除，但如果客户端还活着，定时任务还是会将实例注册上去。但是改成这个状态，定时任务更新不了这个状态</div>
      <h1>General Info</h1>

      <table id='generalInfo' class="table table-striped table-hover">
        <thead>
          <tr><th>Name</th><th>Value</th></tr>
        </thead>
        <tbody>
          <#list statusInfo.generalStats?keys as stat>
            <tr>
              <td>${stat}</td><td>${statusInfo.generalStats[stat]!""}</td>
            </tr>
          </#list>
          <#list statusInfo.applicationStats?keys as stat>
            <tr>
              <td>${stat}</td><td>${statusInfo.applicationStats[stat]!""}</td>
            </tr>
          </#list>
        </tbody>
      </table>

      <h1>Instance Info</h1>

      <table id='instanceInfo' class="table table-striped table-hover">
        <thead>
          <tr><th>Name</th><th>Value</th></tr>
        <thead>
        <tbody>
          <#list instanceInfo?keys as key>
            <tr>
              <td>${key}</td><td>${instanceInfo[key]!""}</td>
            </tr>
          </#list>
        </tbody>
      </table>
    </div>
    <script type="text/javascript" src="eureka/js/wro.js" ></script>
    <script type="text/javascript">
       $(document).ready(function() {
         $('table.stripeable tr:odd').addClass('odd');
         $('table.stripeable tr:even').addClass('even');
       });

       //删除实例 客户端还活着，还会注册上来
       function deleteInstance(appName,instanceId) {
           var url = "/eureka/apps/"+appName+"/"+instanceId;
           httpapi(url,'','DELETE');
           alert('删除成功');
           window.location.reload();//刷新页面
       }
       //将实例设置为下线
       function outInstance(appName,instanceId) {
           var url = "/eureka/apps/"+appName+"/"+instanceId+"/status";
           var param = [];
           param['value']="OUT_OF_SERVICE";
           httpapi(url,param,'PUT');
           alert('下线成功');
           window.location.reload();//刷新页面
       }
       //将实例设置为上线
       function upInstance(appName,instanceId) {
           var url = "/eureka/apps/"+appName+"/"+instanceId+"/status";
           var param = [];
           param['value']="UP";
           httpapi(url,param,'DELETE');
           alert('下线成功');
           window.location.reload();//刷新页面
       }

       //http请求实例
       function httpapi(url,opt,methods) {
           return new Promise(function(resove,reject){
               methods = methods || 'POST';
               var xmlHttp = null;
               if (XMLHttpRequest) {
                   xmlHttp = new XMLHttpRequest();
               } else {
                   xmlHttp = new ActiveXObject('Microsoft.XMLHTTP');
               };
               var params = [];
               for (var key in opt){
                   if(!!opt[key] || opt[key] === 0){
                       params.push(key + '=' + opt[key]);
                   }
               };
               var postData = params.join('&');
               if (methods.toUpperCase() === 'POST') {
                   xmlHttp.open('POST', url, true);
                   xmlHttp.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded;charset=utf-8');
                   xmlHttp.send(postData);
               }else if (methods.toUpperCase() === 'GET') {
                   xmlHttp.open('GET', url + '?' + postData, true);
                   xmlHttp.send(null);
               }else if(methods.toUpperCase() === 'DELETE'){
                   xmlHttp.open('DELETE', url + '?' + postData, true);
                   xmlHttp.send(null);
               }else if(methods.toUpperCase() === 'PUT'){
                   xmlHttp.open('PUT', url + '?' + postData, true);
                   xmlHttp.send(null);
               }
               xmlHttp.onreadystatechange = function () {
                   if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
                      // resove(JSON.parse(xmlHttp.responseText));
                   }
               };
           });
       }
    </script>
  </body>
</html>
