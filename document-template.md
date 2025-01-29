---
title: "Document Template"
author: ""
date: ""
geometry: 
  - margin-top=1in
  - margin-bottom=1in
  - margin-left=1in
  - margin-right=1in
toc: true
toc-title: "Table of Contents"
---

<style>
@page {
    @top-center {
        content: "header";
        font-size: 12pt;
        font-weight: bold;
    }
    @bottom-center {
        content: "footer";
        font-size: 12pt;
        font-weight: bold;
    }
    @bottom-right {
        content: "Page " counter(page);
        font-size: 10pt;
        color: black;
    }
    size: A4;
    margin: 1in;
}

body {
    margin: 0;
    padding: 0;
    font-family: Arial, sans-serif;
    position: relative;
}

.watermark {
    position: fixed;
    top: 35%;
    left: 10%;
    width: 80%;
    text-align: center;
    font-size: 80px;
    font-weight: bold;
    color: rgba(255, 0, 0, 0.1); 
    transform: rotate(-30deg);
    z-index: -1;
    pointer-events: none;
}

.version-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
}

.version-table th, .version-table td {
    border: 1px solid black;
    padding: 8px;
    text-align: left;
}

.version-table th {
    background-color: #f2f2f2;
}
</style>

<div class="watermark">DRAFT</div>

# **Corporate Document Title**
### Author: MYNAME  
### Date: \today  

---

## **Document Version Control**
<table class="version-table">
<tr>
    <th>Version</th>
    <th>Date</th>
    <th>Author</th>
    <th>Change Description</th>
</tr>
<tr>
    <td>1.0</td>
    <td>2024-01-01</td>
    <td>MYNAME</td>
    <td>Initial Draft</td>
</tr>
<tr>
    <td>1.1</td>
    <td>2024-02-15</td>
    <td>MYNAME</td>
    <td>Updated with review comments</td>
</tr>
<tr>
    <td>1.2</td>
    <td>2024-03-05</td>
    <td>MYNAME</td>
    <td>Finalized</td>
</tr>
</table>

---

## **Table of Contents**


---


</div>
