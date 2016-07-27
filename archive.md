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
      <ul>
      {% endunless %}
      <h5>{{ currentyear }}</h5>
      </ul>
      {% capture year %}{{currentyear}}{% endcapture %} 
    {% endif %}
    <li> {{ post.date | date: "%m-%d" }} - <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></li>
{% endfor %}
</div>
