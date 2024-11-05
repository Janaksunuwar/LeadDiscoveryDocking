#!/usr/bin/env nextflow

process sayHello {
    
    script:
    """
    echo "hello how are you doingg?"
    """
}

process sayHi {
    
    script:
    """
    echo "Hi there"
    """
}


process addStuff {
    
    script:
    """
    #!/usr/bin/env python
    x = 5
    y =10
    added = x + y
    print(f'The added value is {added}')
    """
}


process p3 {

    script:
    """
    #!/usr/bin/env python
    print("This is awesome")
    """
}




workflow {
    sayHello()
    sayHi()
    addStuff()
    p3()
}


