---
layout: page
title: 归档
permalink: /archive/
banner_image: life.jpg
---

<div>
{% for post in site.posts %}
    {% capture currentyear %}{{post.date | date: "%Y"}}{% endcapture %}
    <!-- {% if currentyear != year %}
      {% unless forloop.first %}
      {% endunless %}
      <ul>
      <h5>{{ currentyear }}</h5>
      {% capture year %}{{currentyear}}{% endcapture %} 
      
    {% endif %} -->
    <ul>
    <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></li>
    </ul>
    
{% endfor %}
</div>
