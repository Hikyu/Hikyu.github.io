---
layout: page
title: 归档
permalink: /archive/
banner_image: life.jpg
---

<!-- <div>
{% for post in site.posts %}
    {% capture currentyear %}{{post.date | date: "%Y"}}{% endcapture %}
    {% if currentyear != year %}
      {% unless forloop.first %}
      {% endunless %}
      <ul>
      <h5>{{ currentyear }}</h5>
      {% capture year %}{{currentyear}}{% endcapture %} 
      
    {% endif %}
    <h5>{{ currentyear }}</h5>

    {%for month in capture %}
    <ul>
  	  <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></li>
    </ul>
    
{% endfor %}
</div> -->

<div>
	{% capture archives_year %}
    	{{ 'now' | date: '%Y' }}
	{% endcapture %}
	{% for post in site.posts %}
   	 	{% capture post_year %}
        	{{ post.date | date: '%Y' }}
   	 	{% endcapture %}
    	{% if archives_year != post_year %}
        	{% assign archives_year = post_year %}
        	<h2>{{ archives_year }}</h2>
   		{% endif %}
    {{ post.date | date: "%m-%d" }} - <a href="{{post.url}}">{{ post.title }}</a> </br>
	{% endfor %}
</div>
