---
layout: post
title: "Working in GatsbyJS with Typescript Pt. 1"
excerpt_separator: <!--more-->
author: isaacbroyles
tags:
  - typescript
  - gatsbyjs
---

I am spinning up my first GatsbyJS site using Typescript. These are my findings while doing so.

<!--more-->

I'm a fan of strongly typed languages. So as I started my excursion into GatsbyJS, I definitely wanted to use Typescript instead of Javascript.

One of the first issues I ran across was getting strongly typed GraphQL query types in my `.tsx` (Typescript React) files.

## Prerequisites

I used a community gatsby starter to start my project:

```bash
gatsby new gatsby-starter-typescript https://github.com/haysclark/gatsby-starter-typescript
```

There are other starters for typescript, but they have quite a bit more "features". I wanted to learn a bit about GatsbyJS myself, so I started with a minimal project.

## Using gql-gen to generate type files

After some investigation, it appeared the recommended way for strongly-typing your GraphQL query models, was to generate types using the [gql-gen](https://github.com/dotansimha/graphql-code-generator) tool.

Following the documentation [here](https://github.com/dotansimha/graphql-code-generator#installation), I installed a few dev dependencies into my project:

```bash
npm install --save-dev graphql-code-generator graphql
npm install --save-dev graphql-codegen-typescript-template
```

Now, the way `gql-gen` works is by analyzing a schema. This can be done a couple of different ways, either by passing a json schema file on the command line, or by passing a graphql server endpoint to the tool.

It feels like a chicken-egg scenario, but I chose to go ahead and pass the GatsbyJS hosted graphql endpoint to the gql-gen tool.

You can do so by serving up your GatsbyJS site, e.g. `gatsby develop`, and using the `http://localhost:8000/___graphql` endpoint as your source:

```bash
gql-gen --schema http://localhost:8000/___graphql  --template graphql-codegen-typescript-template --out ./src/graphql.d.ts \"./src/**/*.graphql\"
```

As you can see here, I'm outputting my type definitions to `/src/graphql.d.ts`.

## Using the generated types in your components

From here, it's pretty simple to import the types into your React components:

{% highlight typescript %}
import { MyType } from '../graphql';
{% endhighlight %}

Now you have strongly typed models in your Typescript React components!

{% highlight typescript %}
interface IndexPageProps {
  theme: Theme;
  data: {
    site: {
      siteMetadata: {
        title: string,
      },
    },
    myData: MyType,
  };
}

export default class IndexPage extends React.Component<IndexPageProps, {}> {
  public render() {
    const { title } = this.props.data.site.siteMetadata;
    return (
      <Layout>
        <ResponsiveDrawer theme={theme} data={this.props.data.myData} />
      </Layout>
    );
  }
}
{% endhighlight %}