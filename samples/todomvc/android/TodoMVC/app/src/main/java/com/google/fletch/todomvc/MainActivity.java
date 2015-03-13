// Copyright (c) 2015, the Fletch project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

package com.google.fletch.todomvc;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.support.v7.app.ActionBarActivity;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;

import java.util.ArrayList;

import fletch.Cons;
import fletch.Node;
import fletch.PatchSet;
import fletch.Str;
import fletch.TodoMVCService;
import fletch.Uint8List;

public class MainActivity extends ActionBarActivity implements AdapterView.OnItemClickListener {
  private final int REQUEST_NEW_TODO = 0;

  private ListView todoList;
  private TodoMVCImpl impl;

  private enum Context { IN_LIST, IN_ITEM, IN_TITLE, IN_DONE }

  private class TodoMVCImpl extends TodoMVCPresenter {
    // List view/adapter data.
    private ArrayList<TodoItem> todos = new ArrayList<TodoItem>();
    private TodoListAdapter adapter;
    private ListView view;

    // State for patch application.
    private Context context = Context.IN_LIST;
    private int index = 0;

    public TodoMVCImpl(ListView view) {
      this.view = view;
      this.adapter = new TodoListAdapter(view.getContext(), todos);
      this.view.setAdapter(adapter);
      TodoMVCService.reset();
    }

    @Override
    protected void enterPatch() {
      context = Context.IN_LIST;
      index = 0;
    }

    @Override
    protected void enterConsFst() {
      context = (context == Context.IN_ITEM) ? Context.IN_TITLE : Context.IN_ITEM;
    }

    @Override
    protected void enterConsSnd() {
      if (context == Context.IN_ITEM) {
        context = Context.IN_DONE;
      } else {
        ++index;
      }
    }

    @Override
    protected void updateNode(Node node) {
      switch (context) {
        case IN_TITLE:
          todos.get(index).title = decodeStr(node.getStr());
          break;
        case IN_DONE:
          todos.get(index).status = node.getBool();
          break;
        case IN_ITEM:
          todos.set(index, newTodoItem(node));
          break;
        case IN_LIST:
          todos.subList(index, todos.size()).clear();
          addItems(node);
          break;
        default:
          assert false;
      }
    }

    private TodoItem newTodoItem(Node node) {
      Cons cons = node.getCons();
      Str title = cons.getFst().getStr();
      boolean status = cons.getSnd().getBool();
      return new TodoItem(decodeStr(title), status);
    }

    private void addItem(Node node) {
      todos.add(newTodoItem(node));
    }

    private void addItems(Node node) {
      while (node.isCons()) {
        Cons cons = node.getCons();
        addItem(cons.getFst());
        node = cons.getSnd();
      }
    }

    private String decodeStr(Str str) {
      Uint8List chars = str.getChars();
      StringBuilder builder = new StringBuilder(chars.size());
      for (int i = 0; i < chars.size(); ++i) {
        builder.append((char) chars.get(i));
      }
      return builder.toString();
    }

    public void refresh() {
      PatchSet patchSet = TodoMVCService.sync();
      if (patchSet.getPatches().size() > 0) {
        adapter.setNotifyOnChange(false);
        applyPatches(patchSet);
        adapter.notifyDataSetChanged();
      }
    }
  }

  private final Handler handler = new Handler();

  private final Runnable runner = new Runnable() {
    @Override
    public void run() {
      impl.refresh();
      handler.postDelayed(this, 1000);
    }
  };

  private void initiateSync() {
    handler.removeCallbacks(runner);
    handler.postDelayed(runner, 0);
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    todoList = (ListView)MainActivity.this.findViewById(R.id.todo_list);
    impl = new TodoMVCImpl(todoList);
    todoList.setOnItemClickListener(this);
  }

  @Override
  protected void onResume() {
    super.onResume();
    initiateSync();
  }

  @Override
  protected void onPause() {
    super.onPause();
    handler.removeCallbacks(runner);
  }

  @Override
  public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
    impl.completeItem(position);
    initiateSync();
  }

  @Override
  public boolean onCreateOptionsMenu(Menu menu) {
    // Inflate the menu; this adds items to the action bar if it is present.
    getMenuInflater().inflate(R.menu.menu_main, menu);
    return true;
  }

  @Override
  public boolean onOptionsItemSelected(MenuItem item) {
    int id = item.getItemId();
    if (id == R.id.action_new_todo) {
      Intent intent = new Intent(this, CreateTodoItem.class);
      startActivityForResult(intent, REQUEST_NEW_TODO);
      return true;
    }
    return super.onOptionsItemSelected(item);
  }

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent data) {
    if (REQUEST_NEW_TODO == requestCode &&
        RESULT_OK == resultCode) {
      impl.createItem(data.getStringExtra("ItemTitle"));
      initiateSync();
      return;
    }
  }
}
