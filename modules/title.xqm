xquery version "3.0";

module namespace title="http://bluemountain.princeton.edu/modules/title";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://bluemountain.princeton.edu/config" at "config.xqm";
import module namespace app="http://bluemountain.princeton.edu/modules/app" at "app.xql";
import module namespace issue="http://bluemountain.princeton.edu/modules/issue" at "issue.xqm";

declare namespace mets="http://www.loc.gov/METS/";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace xlink="http://www.w3.org/1999/xlink";

declare %templates:wrap function title:selected-title($node as node(), $model as map(*), $titleURN as xs:string?)
as map(*)? 
{
    if ($titleURN) then
        let $titleRec := collection($config:data-root)//mods:identifier[@type='bmtn' and . = $titleURN]/ancestor::mods:mods
        return map { "selected-title" := $titleRec }    
     else ()
};

declare function title:icon($node as node(), $model as map(*))
as element()*
{
    let $selected-title := $model("selected-title")
    let $bmtnid := fn:tokenize($selected-title/mods:identifier[@type='bmtn'], ':')[last()]
    let $path-to-icon := "/exist/rest/" || $config:app-root || "/resources/icons/periodicals"

    return 
        <img src="{string-join(($path-to-icon, $bmtnid, 'large.jpg'), '/')}"
             alt="icon" />
    
};


declare %templates:wrap function title:label($node as node(), $model as map(*))
as element()
{
    let $selected-title := $model("selected-title")
    let $xsl := doc($config:app-root || "/resources/xsl/title.xsl")
    let $xslt-parameters := 
        <parameters>
            <param name="context" value="selected-title-label"/>
        </parameters>
    return transform:transform($selected-title, $xsl, $xslt-parameters)
};

declare %templates:wrap function title:abstract($node as node(), $model as map(*))
as xs:string
{
    let $abstract := $model("selected-title")/mods:abstract
    return
        if ($abstract) then
            xs:string($abstract)
        else
            "No abstract available"
};

declare function title:issues($node as node(), $model as map(*))
as map(*)
{
    let $titleURN := $model("selected-title")/mods:identifier[@type='bmtn']
    let $issues := 
        for $issue in
            collection($config:data-root)//mods:mods[mods:relatedItem[@type='host']/@xlink:href = $titleURN]
        let $date := $issue/mods:originInfo/mods:dateIssued[@keyDate='yes']
        order by xs:dateTime(app:w3cdtf-to-xsdate($date))
        return $issue
    return map { "selected-title-issues" := $issues }
};

declare function title:issue-listing-table($node as node(), $model as map(*))
as element()
{
    <table class="table">
        <tr><th>Volume</th><th>Number</th><th>Date Issued</th><th>Access</th></tr>
    {
    for $issue in $model("selected-title-issues")
        let $issueURN   := xs:string($issue/mods:identifier[@type='bmtn'])
        let $titleURN   := $issue/mods:relatedItem[@type='host']/@xlink:href
        let $vollabel   := $issue/mods:part[@type='issue']/mods:detail[@type='volume']/mods:number
        let $issuelabel := $issue/mods:part[@type='issue']/mods:detail[@type='number']/mods:number
        let $date       := $issue/mods:originInfo/mods:dateIssued[@keyDate='yes']
    order by xs:dateTime(app:w3cdtf-to-xsdate($date))
    return
        <tr>
            <td>{$vollabel}</td>
            <td>{$issuelabel}</td>
            <td>{$date/text()}</td>
            <td><a href="issue.html?titleURN={$titleURN}&amp;issueURN={ $issueURN }">detail</a></td>
        </tr>
    }</table>
};

declare function title:issue-listing-dlist($node as node(), $model as map(*))
as element()
{
    <div class="issue-list">
    {
    for $issue in $model("selected-title-issues")
        let $issueURN   := xs:string($issue/mods:identifier[@type='bmtn'])
        let $titleURN   := $issue/mods:relatedItem[@type='host']/@xlink:href
        let $vollabel   := $issue/mods:part[@type='issue']/mods:detail[@type='volume']/mods:number
        let $issuelabel := $issue/mods:part[@type='issue']/mods:detail[@type='number']/mods:number
        let $date       := $issue/mods:originInfo/mods:dateIssued[@keyDate='yes']
        let $veridianlink := app:veridian-url-from-bmtnid($issueURN)
    order by xs:dateTime(app:w3cdtf-to-xsdate($date))
    return
        <dl class="dl-horizontal">
        <dt>Date</dt>
        <dd>{$date/text()}</dd>
        
        <dt>Volume</dt>
        <dd>{$vollabel}</dd>
        
        <dt>Issue</dt>
        <dd>{$issuelabel}</dd>
        
        <dt>Access</dt>
        <dd><a href="issue.html?titleURN={$titleURN}&amp;issueURN={ $issueURN }">catalog</a></dd>
        <dd><a href="{$veridianlink}">archive</a></dd>
        </dl>
    }
    </div>
};

declare function title:link($node as node(), $model as map(*))
as element()
{
    let $titleURN :=$model("selected-title")/mods:identifier[@type = 'bmtn']
    return
        <a href="{app:veridian-title-url-from-bmtnid($titleURN)}">Browse title in the archive</a>
};

declare function title:issue-listing($node as node(), $model as map(*))
as element()*
{
    <ol class="list-inline"> {
      for $issue in $model("selected-title-issues")
        let $issueURN   := xs:string($issue/mods:identifier[@type='bmtn'])
        let $titleURN   := $issue/mods:relatedItem[@type='host']/@xlink:href
        let $vollabel   := $issue/mods:part[@type='issue']/mods:detail[@type='volume']/mods:number
        let $issuelabel := $issue/mods:part[@type='issue']/mods:detail[@type='number']/mods:number
        let $date       := $issue/mods:originInfo/mods:dateIssued[@keyDate='yes']
        let $veridianlink := app:veridian-url-from-bmtnid($issueURN)
        let $thumbURL  := issue:thumbnailURL($issue)
    order by xs:dateTime(app:w3cdtf-to-xsdate($date))
    return
   
    
    <li>

        <img class="thumbnail" src="{$thumbURL}" alt="thumbnail"  />
            <br />
        <dl class="dl-horizontal">
        <dt>Date</dt>
        <dd>{$date/text()}</dd>
        
        <dt>Volume</dt>
        <dd>{$vollabel}</dd>
        
        <dt>Issue</dt>
        <dd>{$issuelabel}</dd>
        </dl>
        <nav>
            <ul>
            <li><a href="issue.html?titleURN={$titleURN}&amp;issueURN={ $issueURN }">Description</a></li>
            <li><a href="{$veridianlink}">Read in archive</a></li>
            </ul>
        </nav>

    </li>
 }</ol>
};

declare function title:issue-listing-with-captions($node as node(), $model as map(*))
as element()
{
    <table class="table">
        <tr><th>Volume</th><th>Number</th><th>Date Issued</th><th>Access</th></tr>
        {
    for $issueByVolume in $model("selected-title-issues")
            let $issueURN := $issueByVolume/mods:identifier[@type='bmtn']/string()
        let $titleURN := $issueByVolume/mods:relatedItem[@type='host']/@xlink:href

    let $vollabel := 
            if ($issueByVolume/mods:part[@type='issue']/mods:detail[@type='volume']/mods:caption) then
                $issueByVolume/mods:part[@type='issue']/mods:detail[@type='volume']/mods:caption[1]
             else   
                $issueByVolume/mods:part[@type='issue']/mods:detail[@type='volume']/mods:number[1]
    let $issuelabel := 
            if ($issueByVolume/mods:part[@type='issue']/mods:detail[@type='number']/mods:caption) then
                $issueByVolume/mods:part[@type='issue']/mods:detail[@type='number']/mods:caption[1]
            else
                $issueByVolume/mods:part[@type='issue']/mods:detail[@type='number']/mods:number[1]
                
     let $volnum   := $issueByVolume/mods:part[@type='issue']/mods:detail[@type='volume']/mods:number[1] or 0 (: 0 if no volume is specified :)
     let $issuenum := $issueByVolume/mods:part[@type='issue']/mods:detail[@type='number']/mods:number[1] or 0 (: 0 if no issue is specified :)
     
    let $date := $issueByVolume/mods:originInfo/mods:dateIssued[@keyDate='yes']
    (: order by xs:integer($volnum[1]),xs:integer($issuenum) :)
    order by xs:dateTime(app:w3cdtf-to-xsdate($date))

    return
        <tr>
            <td>{string($vollabel[1])}</td>
            <td>{string($issuelabel[1])}</td>
            <td>{$date/text()}</td>
            <td><a href="issue.html?titleURN={$titleURN}&amp;issueURN={ $issueURN }">detail</a></td>
        </tr>
    }</table>
};

declare function title:issue-count($node as node(), $model as map(*)) 
as xs:integer 
{ count($model("selected-title-issues")) };

declare function title:size-chart-script($node as node(), $model as map(*))
{
    let $issues := $model("selected-title-issues")
    let $issuedata :=
        for $issue in $issues
            let $date := $issue/mods:originInfo/mods:dateIssued[@keyDate='yes']
            let $pagecount := count($issue/ancestor::mets:mets/mets:structMap[@TYPE='PHYSICAL']/mets:div[@TYPE='Magazine']/mets:div)
            return
                <issue>
                    <date>{ xs:string($date) }</date>
                    <pagecount>{ $pagecount }</pagecount>
                </issue>
     
    let $xsl := doc("../springs/serial_works/resources/xsl/toJSON.xsl")
    return 
        <script type = "text/javascript">
        var data = google.visualization.arrayToDataTable(
            { transform:transform($issuedata, $xsl, ()) }
            );
            
    </script>
};

(:~
    Return a table of names and counts from the contributors property of the model.
    For names with a viaf id (known contributors) we can get an accurate count; for
    unknown contributors, we have to rely on the byline.
    
    Until we have a local authority file, it's too expensive to go out and get an authorized
    name for the viaf id, so we cheat and use the first byline used by that person.
 :)
declare function title:contributor-table($node as node(), $model as map(*))
{
    let $contributors := $model('contributors')
    let $titleURN := $model('selected-title')//mods:identifier[@type='bmtn']
    let $known-contributor-ids := distinct-values($contributors/@valueURI)
    let $unknown-contributors := distinct-values($contributors[empty(@valueURI)]/mods:displayForm)
    let $known-rows :=
        for $authid in $known-contributor-ids
            let $count  := count($contributors[@valueURI = $authid])
            let $label :=  $contributors[@valueURI = $authid][1]/mods:displayForm/text()
            let $link  := 'contributions.html?titleURN=' || $titleURN || '&amp;authid=' || $authid
            return
                <tr>
                    <td>{ $label }</td>
                    <td><a href="{$link}">{ $count }</a></td>
                </tr>
    let $unknown-rows :=
        for $person in $unknown-contributors
            let $count := count($contributors[mods:displayForm = $person])
            let $label := $person
            let $link := ()
            order by $count descending
            return
                <tr>
                    <td>{ $label }</td>
                   <td><a href="{$link}">{ $count }</a></td>  
                </tr>
     let $rows := ($known-rows,$unknown-rows)
           
    
    return 
        <table class="table">
        <caption>Contributors</caption>
        <thead>
           <tr>
             <th>Contributor</th>
             <th>No. of Contributions</th>
           </tr>
         </thead>
         <tbody>
         {
            for $row in $rows
            order by xs:int($row//td[2]/a) descending
            return $row
          }
         </tbody>
        </table>
};








