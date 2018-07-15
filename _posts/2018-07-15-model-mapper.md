---
layout: post
title: "How to effectively use Model Mapper"
tags:
  - java
  - model mapper
---


I had the pleasure of modifying a large code base that extensively used [Model Mapper](http://modelmapper.org/). I ran into some issues using it blindly, and I did not have much luck searching for answers. Most of the information in this blog posts already exists elsewhere, but I was suprised that it was not very visible on google. Hopefully we can correct that.

Here are my tips for effective use of ModelMapper.

## Use and understand PropertyMap

The first thing you should understand are the nuances of configuring a PropertyMap, which I personally found unintuitive. It wasnt until scouring the documentation and a few well written Stack Overflow posts that everything started to click.

If you're like me, this first thing you'll run up against when searching for help is running across an unintuitive example like this:

{% highlight java %}
public class MyMapper extends PropertyMap<Source, Destination>{
    @Override
    protected void configure(){
        map(source.getProperty()).setOther(null);
    }
}
{% endhighlight %}

The reason why this is confusing, is why would I "set" my destination property to null? 

### The configure() function contains EDSL

The answer is, the code in the `configure()` method is not actually executed as part of your mapping at all. It is actually an Embedded Domain Specific Language (EDSL). **This is the number one thing that made my understanding of Model Mapper so much clearer.**

You can read more about how the EDSL works in the [official javadocs](http://modelmapper.org/javadoc/org/modelmapper/PropertyMap.html).

This gist is this:

* The mapping is not executed as Java code. The `PropertyMap.configure()` is not being executed during the mapping process. You can validate this by setting a breakpoint in the method while debugging a mapping.
* The mapping is interpreted by ModelMapper when the mappings are added using `addMapping(...)`.
* `Converter.convert()`'s **are** executing during runtime. So you can do something like this:

{% highlight java %}
public class MyMapper extends PropertyMap<Source, Destination>{
    private Converter<String, String> toUppercase = (c) -> {
        return c.getSource().toUpperCase();
    };

    @Override
    protected void configure(){
        using(toUppercase)
            .map(source.getProperty())
            .setOther(null);
    }
}
{% endhighlight %}

And the code in the `toUppercase` converter will be executed each time the objects are mapped.

### Use TDD when defining mappings

I cover unit testing in the next section, but bring it up here because it can reduce boilerplate. ModelMapper actually does a pretty good job on its own in most cases. If you define what you expect in tests, it will force you to do the bare minimum definition in the PropertyMap.

For example, if you were to naively define a `PropertyMap` without running any tests, you might end up with something as verbose as this:

{% highlight java %}
public class OverkillPropertyMap 
        extends PropertyMap<PersonDto, Person> {

    @Override
    protected void configure() {
        map(source.getFirstName(), destination.getFirstName());
        map(source.getLastName(), destination.getLastName());
        map(source.getEmail(), destination.getEmail());
        map(source.getPhone(), destination.getPhone());
        map(source.getAddress1(), destination.getAddress1());
        map(source.getAddress2(), destination.getAddress2());
        map(source.getCity(), destination.getCity());
        map(source.getState(), destination.getState());
        map(source.getZip(), destination.getZip());
        map(source.getCountry(), destination.getCountry());

    }
}
{% endhighlight %}

This is a contrived example that can seem silly to an experienced developer, but you'd be surprised at how many mappings like these pop up in codebases.

Let's see if we can simplify this in the next section with a unit test.

## Unit Testing

The ModelMapper official docs state that you should always unit test mappings, and I fully agree. As with most issues, it's much easier to catch things in unit tests than later on in the SDLC.

Here are the two things to always cover in your mapping unit tests:

1. **Always** use `ModelMapper.validate()`
2. Verify fields are being mapped with **assertEquals(...)**

### ModelMapper.validate()

The handy method will verify that all destination properties are matched. This is extremely useful if somebody forgets to map a destination property after adding it. In other words, this will protect your mapper from future changes to both source/destination objects.

If you are getting false positives here, you can skip properties in your mapping:

```
skip(destination.getPropertyNotMapped());
```

### Example of effective unit test

Going back to the example from the last section, except let's start with a unit test this time.

A standard unit test would look something like this:

{% highlight java %}
public class PersonMapTests {
    private ModelMapper modelMapper;

    @Before
    public void setup(){
        modelMapper = new ModelMapper();
        modelMapper.addMappings(new PersonMap());
        modelMapper.getConfiguration()
            .setMatchingStrategy(MatchingStrategies.STRICT);
    }

    @Test
    public void map_ShouldValidate_IfObjectsValid(){
        var personDto = preparePersonDto();

        var personModel = 
            modelMapper.map(personDto, Person.class);

        modelMapper.validate();

        assertEquals(
            personDto.getFirstName(), personModel.getFirstName());
        assertEquals(
            personDto.getLastName(), personModel.getLastName());
        assertEquals(
            personDto.getEmail(), personModel.getEmail());
        assertEquals(
            personDto.getPhone(), personModel.getPhone());
        assertEquals(
            personDto.getAddress1(), personModel.getAddress1());
        assertEquals(
            personDto.getAddress2(), personModel.getAddress2());
        assertEquals(
            personDto.getCity(), personModel.getCity());
        assertEquals(
            personDto.getState(), personModel.getState());
        assertEquals(
            personDto.getCountry(), personModel.getCountry());
        assertEquals(
            personDto.getZip(), personModel.getZip());
    }

    private PersonDto preparePersonDto() {
        return new PersonDto.Builder()
                .firstName("Isaac")
                .lastName("Broyles")
                .email("isaacbroyles@example.com")
                .phone("202-555-0129")
                .address1("123 Street")
                .address2("Apt 101")
                .city("Ville")
                .state("TX")
                .zip("12345")
                .country("USA")
                .build();
    }
}
{% endhighlight %}

In running this unit test, I get an error like this:

```
1) Unmapped destination properties found in TypeMap[PersonDto -> Person]:

com.isaacbroyles.examples.modelmapperexamples.models.Person.setLastModified()
```

Uh oh, the `validate()` method is showing us that we have a destination property that is not mapped. So let's define a `PropertyMap` to fix that issue.

Here is the property map, with just the minimal code to fix my error:

{% highlight java %}
public class PersonMap extends PropertyMap<PersonDto, Person> {
    @Override
    protected void configure() {
        map(source.getDateCreated(), 
            destination.getLastModified());
    }
}
{% endhighlight %}

Now I rerun my test -- Oh cool, it passes now.

Compare the `PropertyMap` we ended up with to the `OverkillPropertyMap` in the previous section. All the other properties were automatically mapped, even with `MatchingStrategies.STRICT`.

## Conclusion

I'm somewhat conflicted over whether I like the usage of ModelMapper or not. On the one hand, it provides a good way to reduce boilerplate mapping code. On the other hand, some of the rather unintuitive aspects of it have caused me headache. This isn't necessarily a critique of ModelMapper, and probably speaks more to my inexperience with it than any lacking on the tool's part. It has obviously grown to be a popular tool for a good reason.

Regardless, I thought this post would prove useful to others who are in a codebase that uses ModelMapper, and are running into the same kinds of issues.

## Related Links

* [ModelMapper](http://modelmapper.org/) - The official ModelMapper website. 
* [Excellent StackOverflow answer](https://stackoverflow.com/a/44534173) - I saw this great answer, which prompted me to dig in deeper to get more understanding about ModelMapper's inner workings.