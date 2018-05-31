/**
 * Copyright (C) 2018  Atoiks Games
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.atoiks.games.starfield.server;

import java.util.List;
import java.util.ArrayList;

import java.util.stream.Stream;

import java.util.function.Consumer;
import java.util.function.BiConsumer;

public class CBListWrapper<E> {

    public enum EventType {
        ADD, INSERT, REMOVE, CLEAR;
    }

    public final List<E> list;

    private final List<BiConsumer<EventType, ? super E>> cbacks;

    public CBListWrapper(final List<E> lst) {
        this.list = lst;
        this.cbacks = new ArrayList<>();
    }

    public void addCallback(final BiConsumer<EventType, ? super E> cb) {
        cbacks.add(cb);
    }

    public void removeCallback(final BiConsumer<EventType, ? super E> cb) {
        cbacks.remove(cb);
    }

    public void add(final E e) {
        cbacks.forEach(cb -> cb.accept(EventType.ADD, e));
        this.list.add(e);
    }

    public void insert(final int index, final E e) {
        cbacks.forEach(cb -> cb.accept(EventType.INSERT, e));
        this.list.add(index, e);
    }

    public void remove(final E e) {
        final boolean k = this.list.remove(e);
        cbacks.forEach(cb -> cb.accept(EventType.REMOVE, k ? e : null));
    }

    public void clear() {
        cbacks.forEach(cb -> cb.accept(EventType.CLEAR, null));
        this.list.clear();
    }

    public Stream<E> stream() {
        return this.list.stream();
    }

    public void forEach(final Consumer<? super E> action) {
        this.list.forEach(action);
    }

    public E get(final int index) {
        return this.list.get(index);
    }

    public int size() {
        return this.list.size();
    }

    /**
     * Wraps an empty {@link java.util.ArrayList}
     */
    public static <T> CBListWrapper<T> newList() {
        return new CBListWrapper<>(new ArrayList<>());
    }
}