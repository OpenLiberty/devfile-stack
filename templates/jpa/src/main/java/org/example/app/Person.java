/*
 * Copyright (c) 2019 IBM Corporation and others
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.example.app;

import java.util.Objects;
import java.util.Random;

//import javax.json.bind.annotation.JsonbCreator;
//import javax.json.bind.annotation.JsonbProperty;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.PositiveOrZero;
import javax.validation.constraints.Size;

import java.io.Serializable;
import javax.persistence.Table;
import javax.persistence.NamedQuery;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;

@Entity
@Table(name = "Person")
@NamedQuery(name = "Person.findAll", query = "SELECT p FROM Person p")
@NamedQuery(name = "Person.findPerson", query = "SELECT p FROM Person p WHERE "
                 + "p.name = :name AND p.age = :age")
public class Person implements Serializable {
    private static final long serialVersionUID = 1L;

    private static final Random r = new Random();

    @NotNull
    @Id
    @Column(name = "personId")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public long id;

    @NotNull
    @Size(min = 2, max = 50)
    @Column(name = "name")
    public String name;

    @NotNull
    @PositiveOrZero
    @Column(name = "age")
    public int age;
     
    public void setName(String name) {
        this.name = name;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public Person() {
    }    
 
    public Person(String name, int age) {
        this(name, age, null);
    }

    //@JsonbCreator
    public Person(String name,
                  int age,
                  Long id) {
        this.name = name;
        this.age = age;
        this.id = id == null ? r.nextLong() : id;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof Person))
            return false;
        Person other = (Person) obj;
        return Objects.equals(id, other.id) &&
               Objects.equals(name, other.name) &&
               Objects.equals(age, other.age);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, age);
    }

}
