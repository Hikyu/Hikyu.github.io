---
layout: page
title: 归档
permalink: /archive/
banner_image: life.jpg
---

<div>
{% for post in site.posts %}
    {% capture currentyear %}{{post.date | date: "%Y"}}{% endcapture %}
    {% if currentyear != year %}
      {% unless forloop.first %}
      
      {% endunless %}
      <h3>{{ currentyear }}</h3>
   
      {% capture year %}{{currentyear}}{% endcapture %} 
    {% endif %}
    <li> {{ post.date | date: "%m-%d" }} - <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></li>
{% endfor %}
</div>
